import Foundation
import Testing
@testable import CCPet

@Suite("Models Tests")
struct ModelsTests {

    // MARK: - PetState

    @Test("PetState has all required cases")
    func petStateHasAllCases() {
        let allCases: [PetState] = [.sleeping, .awake, .thinking, .working, .celebrating, .error]
        #expect(allCases.count == 6)
    }

    @Test("PetState default is sleeping")
    func petStateDefaultIsSleeping() {
        let state = PetState.sleeping
        #expect(state == .sleeping)
    }

    // MARK: - HookEvent

    @Test("HookEvent decodes from valid JSON")
    func hookEventDecodesFromJSON() throws {
        let json = """
        {
            "event": "PreToolUse",
            "session_id": "abc-123",
            "cwd": "/Users/test/project",
            "timestamp": 1715644800,
            "tool": "Bash",
            "tool_input": {"command": "ls"}
        }
        """
        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(HookEvent.self, from: data)
        #expect(event.event == "PreToolUse")
        #expect(event.sessionId == "abc-123")
        #expect(event.cwd == "/Users/test/project")
        #expect(event.timestamp == 1715644800)
        #expect(event.tool == "Bash")
    }

    @Test("HookEvent decodes with optional fields missing")
    func hookEventDecodesWithMissingOptionals() throws {
        let json = """
        {
            "event": "SessionStart",
            "session_id": "xyz-456",
            "cwd": "/Users/test/other",
            "timestamp": 1715644900
        }
        """
        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(HookEvent.self, from: data)
        #expect(event.event == "SessionStart")
        #expect(event.tool == nil)
        #expect(event.toolInput == nil)
        #expect(event.success == nil)
    }

    // MARK: - Session

    @Test("Session initializes with correct defaults")
    func sessionInitializesCorrectly() {
        let session = Session(id: "abc-123", cwd: "/Users/test/project")
        #expect(session.id == "abc-123")
        #expect(session.state == .sleeping)
        #expect(session.recentEvents.isEmpty)
        #expect(session.projectName == "project")
    }

    @Test("Session extracts project name from cwd")
    func sessionExtractsProjectName() {
        let session = Session(id: "s1", cwd: "/Users/developer/Projects/sample-app")
        #expect(session.projectName == "sample-app")
    }

    @Test("Session addEvent keeps max 20 events")
    func sessionAddEventKeepsMax20() {
        var session = Session(id: "s1", cwd: "/tmp/test")
        for i in 0..<25 {
            let event = HookEvent(
                event: "PreToolUse",
                sessionId: "s1",
                cwd: "/tmp/test",
                timestamp: Int(i),
                tool: "Bash",
                toolInput: nil,
                success: nil
            )
            session.addEvent(event)
        }
        #expect(session.recentEvents.count == 20)
        #expect(session.recentEvents.first?.timestamp == 24)
    }
}
