import Testing
import Foundation
@testable import CCPet

@Suite("SocketServer Tests")
struct SocketServerTests {

    @Test("SocketServer receives JSON event from client connection")
    @MainActor
    func socketServerReceivesEvent() async throws {
        let socketPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).sock").path

        let receivedEvents = ActorBox<[HookEvent]>([])

        let server = SocketServer(socketPath: socketPath) { event in
            await receivedEvents.append(event)
        }
        try server.start()

        // Allow server to start listening
        try await Task.sleep(for: .milliseconds(100))

        // Send a test event via raw POSIX socket connection
        let json = """
        {"event":"PreToolUse","session_id":"test-1","cwd":"/tmp","timestamp":1715644800,"tool":"Bash"}

        """
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        #expect(fd >= 0)
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        socketPath.withCString { ptr in
            withUnsafeMutablePointer(to: &addr.sun_path.0) { dest in
                _ = strcpy(dest, ptr)
            }
        }
        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        #expect(connectResult == 0)
        json.withCString { ptr in
            _ = write(fd, ptr, strlen(ptr))
        }
        close(fd)

        // Allow processing
        try await Task.sleep(for: .milliseconds(500))

        let events = await receivedEvents.value
        #expect(events.count == 1)
        #expect(events.first?.event == "PreToolUse")
        #expect(events.first?.sessionId == "test-1")

        server.stop()
        try? FileManager.default.removeItem(atPath: socketPath)
    }
}

actor ActorBox<T> {
    var value: T
    init(_ initial: T) { value = initial }
}

extension ActorBox where T == [HookEvent] {
    func append(_ item: HookEvent) {
        value.append(item)
    }
}
