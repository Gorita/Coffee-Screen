import Foundation

/// 시스템 수면 및 화면 꺼짐 방지를 관리하는 컨트롤러
/// macOS 내장 `/usr/bin/caffeinate` 서브프로세스를 활용하며,
/// 부모 프로세스 생명주기(-w <PID>)를 결합하고 OS 커널의 `terminationHandler` 이벤트를 기반으로
/// 무부하(0% CPU) 및 고아 프로세스 원천 방지를 보장합니다.
final class PowerController {

    // MARK: - Properties

    private var caffeinateProcess: Process?

    /// 프로세스 생존 상태 변경 콜백 (Main Thread 보장)
    var onStateChange: ((Bool) -> Void)?

    /// 실제 프로세스가 현재 실행 중인지 여부 (Single Source of Truth)
    private(set) var isActive: Bool = false {
        didSet {
            if oldValue != isActive {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.onStateChange?(self.isActive)
                }
            }
        }
    }

    // MARK: - Public Methods

    /// 시스템 수면 방지 및 화면 꺼짐 방지 시작
    /// - Returns: 성공 시 .success, 실패 시 .failure(PowerError)
    @discardableResult
    func startAwake() -> Result<Void, PowerError> {
        // 이미 활성화되어 실행 중인 경우 기존 프로세스 정리 후 재시작
        if isActive {
            stopAwake()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        
        let parentPID = ProcessInfo.processInfo.processIdentifier
        
        // -d: 디스플레이 꺼짐 방지 (Prevent display sleep)
        // -i: 시스템 유휴 잠자기 방지 (Prevent idle sleep)
        // -m: 디스크 유휴 절전 방지 (Prevent disk idle sleep)
        // -u: 사용자 활성 상태 선언 (Declare user active)
        // -w <PID>: 부모 프로세스가 종료되면 OS 커널이 caffeinate를 즉시 자동 회수 (고아 방지)
        process.arguments = ["-d", "-i", "-m", "-u", "-w", "\(parentPID)"]

        // 커널 레벨 프로세스 종료 이벤트 감시 (무부하 0% CPU 이벤트 방식)
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleProcessTermination()
            }
        }

        do {
            try process.run()
            self.caffeinateProcess = process
            self.isActive = true
            return .success(())
        } catch {
            self.caffeinateProcess = nil
            self.isActive = false
            return .failure(.assertionCreationFailed)
        }
    }

    /// 시스템 수면 및 화면 꺼짐 방지 해제
    func stopAwake() {
        if let process = caffeinateProcess {
            // 수동 종료 시 중복 핸들러 트리거 방지
            process.terminationHandler = nil
            if process.isRunning {
                process.terminate()
            }
        }
        caffeinateProcess = nil
        isActive = false
    }

    // MARK: - Private Methods

    /// 프로세스가 외부 요인 또는 OS에 의해 종료되었을 때 호출되는 커널 핸들러
    private func handleProcessTermination() {
        caffeinateProcess = nil
        isActive = false
    }

    // MARK: - Deinit

    deinit {
        stopAwake()
    }
}

// MARK: - PowerError

enum PowerError: Error, LocalizedError {
    case assertionCreationFailed
    case assertionReleaseFailed

    var errorDescription: String? {
        switch self {
        case .assertionCreationFailed:
            return "시스템 수면 방지(caffeinate) 활성화에 실패했습니다."
        case .assertionReleaseFailed:
            return "시스템 수면 방지(caffeinate) 해제에 실패했습니다."
        }
    }
}
