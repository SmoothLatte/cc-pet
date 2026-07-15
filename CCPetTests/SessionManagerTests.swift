import Testing
import Foundation
@testable import CCPet

@Suite("SessionManager Tests")
struct SessionManagerTests {

    private func makeEvent(_ eventType: String, session: String = "s1", cwd: String = "/tmp/project-a", tool: String? = nil, success: Bool? = nil) -> HookEvent {
        HookEvent(
            event: eventType,
            sessionId: session,
            cwd: cwd,
            timestamp: Int(Date().timeIntervalSince1970),
            tool: tool,
            toolInput: nil,
            success: success
        )
    }

    @Test("handleEvent creates new session on SessionStart")
    @MainActor
    func handleEventCreatesNewSession() {
        let manager = SessionManager()
        let event = makeEvent("SessionStart")
        manager.handleEvent(event)
        #expect(manager.sessions.count == 1)
        #expect(manager.sessions["s1"]?.state == .awake)
    }

    @Test("handleEvent updates existing session state")
    @MainActor
    func handleEventUpdatesSessionState() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("UserPromptSubmit"))
        #expect(manager.sessions["s1"]?.state == .thinking)
    }

    @Test("handleEvent tracks multiple sessions")
    @MainActor
    func handleEventTracksMultipleSessions() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart", session: "s1", cwd: "/tmp/project-a"))
        manager.handleEvent(makeEvent("SessionStart", session: "s2", cwd: "/tmp/project-b"))
        #expect(manager.sessions.count == 2)
        #expect(manager.sessions["s1"]?.projectName == "project-a")
        #expect(manager.sessions["s2"]?.projectName == "project-b")
    }

    @Test("handleEvent removes session on SessionEnd after delay flag")
    @MainActor
    func handleEventSleepsOnSessionEnd() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("SessionEnd"))
        #expect(manager.sessions["s1"]?.state == .sleeping)
    }

    @Test("handleEvent adds event to session history")
    @MainActor
    func handleEventAddsToHistory() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("PreToolUse", tool: "Bash"))
        #expect(manager.sessions["s1"]?.recentEvents.count == 2)
    }

    @Test("handleEvent sets currentTool on PreToolUse")
    @MainActor
    func handleEventSetsCurrentTool() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("PreToolUse", tool: "Bash"))
        #expect(manager.sessions["s1"]?.currentTool == "Bash")
    }

    @Test("handleEvent clears currentTool on PostToolUse")
    @MainActor
    func handleEventClearsCurrentTool() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("PreToolUse", tool: "Bash"))
        manager.handleEvent(makeEvent("PostToolUse", tool: "Bash", success: true))
        #expect(manager.sessions["s1"]?.currentTool == nil)
    }

    @Test("activeSession defaults to most recently active session")
    @MainActor
    func activeSessionDefaultsToMostRecent() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart", session: "s1"))
        manager.handleEvent(makeEvent("SessionStart", session: "s2"))
        #expect(manager.activeSessionId == "s2")
    }

    @Test("failureCount increments on PostToolUseFailure")
    @MainActor
    func failureCountIncrements() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        manager.handleEvent(makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        manager.handleEvent(makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        #expect(manager.consecutiveFailures(for: "s1") == 3)
    }

    @Test("failureCount resets on PostToolUse success")
    @MainActor
    func failureCountResetsOnSuccess() {
        let manager = SessionManager()
        manager.handleEvent(makeEvent("SessionStart"))
        manager.handleEvent(makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        manager.handleEvent(makeEvent("PostToolUseFailure", tool: "Bash", success: false))
        manager.handleEvent(makeEvent("PostToolUse", tool: "Bash", success: true))
        #expect(manager.consecutiveFailures(for: "s1") == 0)
    }
}
