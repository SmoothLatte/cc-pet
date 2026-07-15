import Foundation
import Testing
@testable import CCPet

@Suite("EventEngine Tests")
struct EventEngineTests {

    private func makeEvent(_ eventType: String, session: String = "s1", tool: String? = nil, success: Bool? = nil) -> HookEvent {
        HookEvent(
            event: eventType,
            sessionId: session,
            cwd: "/tmp/test",
            timestamp: Int(Date().timeIntervalSince1970),
            tool: tool,
            toolInput: nil,
            success: success
        )
    }

    @Test("SessionStart transitions to awake")
    func sessionStartTransitionsToAwake() {
        let newState = EventEngine.nextState(current: .sleeping, event: makeEvent("SessionStart"))
        #expect(newState == .awake)
    }

    @Test("UserPromptSubmit transitions to thinking")
    func userPromptSubmitTransitionsToThinking() {
        let newState = EventEngine.nextState(current: .awake, event: makeEvent("UserPromptSubmit"))
        #expect(newState == .thinking)
    }

    @Test("PreToolUse transitions to working")
    func preToolUseTransitionsToWorking() {
        let newState = EventEngine.nextState(current: .thinking, event: makeEvent("PreToolUse", tool: "Bash"))
        #expect(newState == .working)
    }

    @Test("PostToolUse transitions to awake")
    func postToolUseTransitionsToAwake() {
        let newState = EventEngine.nextState(current: .working, event: makeEvent("PostToolUse", tool: "Bash", success: true))
        #expect(newState == .awake)
    }

    @Test("PostToolUseFailure transitions to error")
    func postToolUseFailureTransitionsToError() {
        let newState = EventEngine.nextState(current: .working, event: makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        #expect(newState == .error)
    }

    @Test("Stop transitions to celebrating")
    func stopTransitionsToCelebrating() {
        let newState = EventEngine.nextState(current: .awake, event: makeEvent("Stop"))
        #expect(newState == .celebrating)
    }

    @Test("SessionEnd transitions to sleeping")
    func sessionEndTransitionsToSleeping() {
        let newState = EventEngine.nextState(current: .awake, event: makeEvent("SessionEnd"))
        #expect(newState == .sleeping)
    }

    @Test("Unknown event does not change state")
    func unknownEventDoesNotChangeState() {
        let newState = EventEngine.nextState(current: .awake, event: makeEvent("UnknownEvent"))
        #expect(newState == .awake)
    }

    @Test("parseEvent handles valid JSON line")
    func parseEventHandlesValidJSON() throws {
        let json = """
        {"event":"PreToolUse","session_id":"s1","cwd":"/tmp","timestamp":1715644800,"tool":"Read"}
        """
        let event = try EventEngine.parseEvent(from: Data(json.utf8))
        #expect(event.event == "PreToolUse")
        #expect(event.tool == "Read")
    }

    @Test("parseEvent throws on invalid JSON")
    func parseEventThrowsOnInvalidJSON() {
        let data = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            try EventEngine.parseEvent(from: data)
        }
    }
}
