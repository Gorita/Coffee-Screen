import Foundation
import SwiftUI

/// Unix Domain Socket 서버 (100% 메모리 안전 POSIX 구현)
@MainActor
final class BulletinSocketServer: ObservableObject {

    static let shared = BulletinSocketServer()

    @Published var isRunning: Bool = false
    @Published var messages: [BulletinMessage] = []

    private var serverFd: Int32 = -1
    private var shouldStop: Bool = false
    private var serverTask: Task<Void, Never>?
    private var dismissTimers: [UUID: Task<Void, Never>] = [:]
    private var config: BulletinBoardConfig = BulletinBoardConfig()

    private init() {}

    // MARK: - Public API

    /// 설정 변경 시 호출 — 필요하면 재시작
    func applyConfig(_ newConfig: BulletinBoardConfig) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let needsRestart = newConfig.isEnabled && (
                !self.config.isEnabled || self.config.socketPath != newConfig.socketPath
            )
            let needsStop = !newConfig.isEnabled && self.config.isEnabled

            self.config = newConfig

            if needsStop {
                self.stop()
            } else if needsRestart {
                self.stop()
                self.start()
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        shouldStop = false
        let path = config.socketPath
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runServer(socketPath: path)
        }
    }

    func stop() {
        shouldStop = true
        let fd = serverFd
        serverFd = -1
        if fd >= 0 {
            Darwin.close(fd)
        }
        unlink(config.socketPath)
        serverTask?.cancel()
        serverTask = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
        }
    }

    func sendTestMessage(style: BulletinDisplayStyle) {
        let samples: [(String, BulletinMessageLevel)] = [
            ("✅ Claude: 테스트 작업 완료!", .success),
            ("ℹ️ 빌드 시작됨: main branch", .info),
            ("⚠️ 경고: 메모리 사용량 80%", .warning),
        ]
        let sample = samples[Int.random(in: 0..<samples.count)]
        addMessage(BulletinMessage(text: sample.0, level: sample.1))
    }

    func clearMessages() {
        dismissTimers.values.forEach { $0.cancel() }
        dismissTimers.removeAll()
        withAnimation { messages.removeAll() }
    }

    // MARK: - Socket Server (POSIX Background Thread)

    private nonisolated func runServer(socketPath: String) {
        // 기존 파일 삭제
        unlink(socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            print("[BulletinSocketServer] socket() 생성 실패")
            return
        }

        Task { @MainActor [weak self] in
            self?.serverFd = fd
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)

        let pathCString = socketPath.utf8CString
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        guard pathCString.count <= maxLen else {
            print("[BulletinSocketServer] 소켓 경로가 너무 깁니다.")
            Darwin.close(fd)
            return
        }

        // 경로 버퍼 안전하게 복사
        _ = pathCString.withUnsafeBufferPointer { bufPtr in
            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                let rawPtr = UnsafeMutableRawPointer(ptr)
                if let base = bufPtr.baseAddress {
                    memcpy(rawPtr, base, bufPtr.count)
                }
            }
        }

        // Unix Domain Socket 바인딩 길이 계산
        let addrLen = socklen_t(MemoryLayout<sa_family_t>.size + pathCString.count)

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, addrLen)
            }
        }

        guard bindResult == 0 else {
            print("[BulletinSocketServer] bind() 실패: errno \(errno)")
            Darwin.close(fd)
            return
        }

        guard listen(fd, 5) == 0 else {
            print("[BulletinSocketServer] listen() 실패")
            Darwin.close(fd)
            return
        }

        // 외부 프로세스 접근을 위해 777 권한 설정
        chmod(socketPath, 0o777)

        DispatchQueue.main.async { [weak self] in
            self?.isRunning = true
        }
        print("[BulletinSocketServer] 소켓 서버 백그라운드 바인딩 성공: \(socketPath)")

        while true {
            let clientFd = accept(fd, nil, nil)
            guard clientFd >= 0 else {
                break
            }
            Task.detached(priority: .utility) { [weak self] in
                self?.handleClient(clientFd)
            }
        }

        Darwin.close(fd)
        unlink(socketPath)
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
        }
    }

    private nonisolated func handleClient(_ clientFd: Int32) {
        defer { Darwin.close(clientFd) }

        var buffer = [UInt8](repeating: 0, count: 2048)
        var accumulator = Data()

        while true {
            let readBytes = recv(clientFd, &buffer, buffer.count, 0)
            guard readBytes > 0 else { break }
            accumulator.append(contentsOf: buffer[0..<readBytes])

            while let nl = accumulator.firstIndex(of: 0x0A) {
                let lineData = accumulator[accumulator.startIndex..<nl]
                if let text = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !text.isEmpty {
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        let msg = self.parseMessage(text)
                        self.addMessage(msg)
                    }
                }
                accumulator.removeSubrange(accumulator.startIndex...nl)
            }
        }

        if !accumulator.isEmpty,
           let text = String(data: accumulator, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let msg = self.parseMessage(text)
                self.addMessage(msg)
            }
        }
    }

    // MARK: - Message Parsing

    private func parseMessage(_ raw: String) -> BulletinMessage {
        if let data = raw.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            let text  = json["text"] ?? raw
            let level = BulletinMessageLevel(rawValue: json["level"] ?? "info") ?? .info
            return BulletinMessage(text: text, level: level)
        }
        return BulletinMessage(text: raw, level: .info)
    }

    // MARK: - Message Management

    @MainActor
    func addMessage(_ message: BulletinMessage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.insert(message, at: 0)
            let max = config.maxMessages
            while messages.count > max {
                let removed = messages.removeLast()
                dismissTimers[removed.id]?.cancel()
                dismissTimers.removeValue(forKey: removed.id)
            }
        }

        scheduleAutoDismiss(for: message.id)
    }

    @MainActor
    private func scheduleAutoDismiss(for id: UUID) {
        let duration = config.autoDismissDuration
        guard duration > 0 else { return }

        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self?.messages.removeAll { $0.id == id }
            }
            self?.dismissTimers.removeValue(forKey: id)
        }
        dismissTimers[id] = task
    }
}
