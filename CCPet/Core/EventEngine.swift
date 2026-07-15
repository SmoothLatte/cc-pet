import Foundation

enum EventEngine {

    static func parseEvent(from data: Data) throws -> HookEvent {
        try JSONDecoder().decode(HookEvent.self, from: data)
    }

    static func nextState(current: PetState, event: HookEvent) -> PetState {
        switch event.event {
        case "SessionStart":
            return .awake
        case "UserPromptSubmit":
            return .thinking
        case "PreToolUse":
            return .working
        case "PostToolUse":
            return .awake
        case "PostToolUseFailure":
            return .error
        case "Stop":
            return .celebrating
        case "SessionEnd":
            return .sleeping
        default:
            return current
        }
    }
}
