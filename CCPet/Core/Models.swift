import Foundation

// MARK: - PetState

enum PetState: String, Sendable {
    case sleeping
    case awake
    case thinking
    case working
    case celebrating
    case error
    case knocking
}

// MARK: - AnyCodableValue

enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(Double.self) { self = .double(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else if container.decodeNil() { self = .null }
        else { self = .null }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - HookEvent

struct HookEvent: Codable, Sendable {
    let event: String
    let sessionId: String
    let cwd: String
    let timestamp: Int
    let tool: String?
    let toolInput: [String: AnyCodableValue]?
    let success: Bool?

    enum CodingKeys: String, CodingKey {
        case event
        case sessionId = "session_id"
        case cwd
        case timestamp
        case tool
        case toolInput = "tool_input"
        case success
    }
}

// MARK: - Session

struct Session: Identifiable, Sendable {
    let id: String
    let cwd: String
    var state: PetState
    var currentTool: String?
    var currentToolInput: String?
    var recentEvents: [HookEvent]
    var lastEventTime: Date

    var projectName: String {
        (cwd as NSString).lastPathComponent
    }

    init(id: String, cwd: String) {
        self.id = id
        self.cwd = cwd
        self.state = .sleeping
        self.currentTool = nil
        self.currentToolInput = nil
        self.recentEvents = []
        self.lastEventTime = Date()
    }

    mutating func addEvent(_ event: HookEvent) {
        recentEvents.insert(event, at: 0)
        if recentEvents.count > 20 {
            recentEvents = Array(recentEvents.prefix(20))
        }
        lastEventTime = Date()
    }
}
