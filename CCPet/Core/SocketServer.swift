import Foundation

final class SocketServer: @unchecked Sendable {
    private let socketPath: String
    private let onEvent: @Sendable (HookEvent) async -> Void
    private var serverFD: Int32 = -1
    private var running = false
    private var acceptThread: Thread?

    init(socketPath: String, onEvent: @escaping @Sendable (HookEvent) async -> Void) {
        self.socketPath = socketPath
        self.onEvent = onEvent
    }

    func start() throws {
        // Remove stale socket file
        try? FileManager.default.removeItem(atPath: socketPath)

        // Ensure parent directory exists
        let dir = (socketPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw SocketServerError.socketCreationFailed(errno)
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        socketPath.withCString { ptr in
            withUnsafeMutablePointer(to: &addr.sun_path.0) { dest in
                _ = strcpy(dest, ptr)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            close(fd)
            throw SocketServerError.bindFailed(errno)
        }

        guard listen(fd, 5) == 0 else {
            close(fd)
            throw SocketServerError.listenFailed(errno)
        }

        serverFD = fd
        running = true

        let thread = Thread { [weak self] in
            self?.acceptLoop()
        }
        thread.qualityOfService = .userInitiated
        thread.name = "com.ccpet.socket.accept"
        thread.start()
        acceptThread = thread
    }

    func stop() {
        running = false
        if serverFD >= 0 {
            close(serverFD)
            serverFD = -1
        }
        try? FileManager.default.removeItem(atPath: socketPath)
    }

    private func acceptLoop() {
        while running {
            var clientAddr = sockaddr_un()
            var clientLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientFD = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    accept(serverFD, sockPtr, &clientLen)
                }
            }
            guard clientFD >= 0 else { break }

            // Handle each client on a detached thread to avoid blocking accept
            Thread.detachNewThread { [weak self] in
                self?.handleClient(clientFD)
            }
        }
    }

    private func handleClient(_ fd: Int32) {
        var buffer = Data()
        let chunkSize = 65536
        let readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer {
            readBuffer.deallocate()
            close(fd)
        }

        while true {
            let bytesRead = read(fd, readBuffer, chunkSize)
            if bytesRead <= 0 { break }
            buffer.append(readBuffer, count: bytesRead)

            if buffer.contains(UInt8(ascii: "\n")) {
                break
            }
        }

        processBuffer(buffer)
    }

    private func processBuffer(_ data: Data) {
        let lines = data.split(separator: UInt8(ascii: "\n"))
        for line in lines {
            guard !line.isEmpty else { continue }
            do {
                let event = try EventEngine.parseEvent(from: Data(line))
                let callback = onEvent
                Task { await callback(event) }
            } catch {
                print("[SocketServer] failed to parse event: \(error)")
            }
        }
    }
}

enum SocketServerError: Error {
    case socketCreationFailed(Int32)
    case bindFailed(Int32)
    case listenFailed(Int32)
}
