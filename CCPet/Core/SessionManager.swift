import Foundation
import SwiftUI

@MainActor
final class SessionManager: ObservableObject {
    @Published var sessions: [String: Session] = [:]
    @Published var activeSessionId: String?

    private var failureCounts: [String: Int] = [:]

    var activeSession: Session? {
        guard let id = activeSessionId else { return nil }
        return sessions[id]
    }

    func handleEvent(_ event: HookEvent) {
        let sessionId = event.sessionId

        if sessions[sessionId] == nil {
            sessions[sessionId] = Session(id: sessionId, cwd: event.cwd)
        }

        let currentState = sessions[sessionId]!.state
        let newState = EventEngine.nextState(current: currentState, event: event)
        sessions[sessionId]!.state = newState
        sessions[sessionId]!.addEvent(event)

        switch event.event {
        case "PreToolUse":
            sessions[sessionId]!.currentTool = event.tool
            if let input = event.toolInput, let cmd = input["command"] {
                sessions[sessionId]!.currentToolInput = "\(cmd)"
            }
        case "PostToolUse":
            sessions[sessionId]!.currentTool = nil
            sessions[sessionId]!.currentToolInput = nil
            failureCounts[sessionId] = 0
        case "PostToolUseFailure":
            sessions[sessionId]!.currentTool = nil
            sessions[sessionId]!.currentToolInput = nil
            failureCounts[sessionId, default: 0] += 1
        case "Stop":
            failureCounts[sessionId] = 0
        default:
            break
        }

        activeSessionId = sessionId
    }

    func consecutiveFailures(for sessionId: String) -> Int {
        failureCounts[sessionId, default: 0]
    }

    func selectSession(_ sessionId: String) {
        activeSessionId = sessionId
    }
}
