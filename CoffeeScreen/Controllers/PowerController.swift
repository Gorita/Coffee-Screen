import Foundation

/// 시스템 수면 및 화면 꺼짐 방지를 관리하는 컨트롤러
/// macOS 내장 `/usr/bin/caffeinate` 서브프로세스를 활용하여
/// OS 레벨에서 가장 강력하고 안정적인 Keep-Awake를 보장합니다.
final class PowerController {

    // MARK: - Properties

    private var caffeinateProcess: Process?

    /// 현재 수면 방지가 활성화되어 있는지 여부
    private(set) var isActive: Bool = false

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
        
        // -d: 디스플레이 꺼짐 방지 (Prevent display sleep)
        // -i: 시스템 유휴 잠자기 방지 (Prevent idle sleep)
        // -m: 디스크 유휴 절전 방지 (Prevent disk idle sleep)
        // -u: 사용자 활성 상태 선언 (Declare user active)
        process.arguments = ["-d", "-i", "-m", "-u"]

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
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
        }
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
