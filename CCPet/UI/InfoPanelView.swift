import SwiftUI

struct InfoPanelView: View {
    @ObservedObject var sessionManager: SessionManager
    var notificationManager: NotificationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().opacity(0.5)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let session = sessionManager.activeSession {
                        currentSessionSection(session)
                        recentEventsSection(session)
                    }
                    sessionsListSection
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 300)
        .padding(.vertical, 4)
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Text("🐷")
                    .font(.system(size: 16))
                Text("cc-pet")
                    .font(.system(size: 14, weight: .semibold))
            }
            Spacer()
            HStack(spacing: 12) {
                headerIconButton(systemName: "info.circle", action: openAbout)
                headerIconButton(systemName: "gearshape", action: openSettings)
                headerIconButton(systemName: "power", action: quitApp, color: .red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
    }

    private func headerIconButton(
        systemName: String,
        action: @escaping () -> Void,
        color: Color = .secondary
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func openSettings() {
        SettingsWindowController.shared.show(notificationManager: notificationManager)
    }

    private func openAbout() {
        AboutWindowController.shared.show()
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @ViewBuilder
    private func currentSessionSection(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "当前会话", accent: .blue)

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.blue)
                    .frame(width: 3)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.projectName)
                            .font(.body.bold())
                            .lineLimit(1)
                        Spacer()
                        StateBadge(state: session.state)
                    }

                    if let tool = session.currentTool {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(tool)
                                .font(.caption)
                                .foregroundColor(.primary)
                            if let input = session.currentToolInput {
                                Text(input)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(duration(since: session.lastEventTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
            }
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func recentEventsSection(_ session: Session) -> some View {
        let filtered = Array(session.recentEvents
            .filter { $0.event != "PreToolUse" }
            .prefix(6))

        if !filtered.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "最近事件", accent: .orange)

                VStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.timestamp) { index, event in
                        HStack(spacing: 6) {
                            Image(systemName: eventIcon(event.event))
                                .font(.caption2)
                                .foregroundColor(eventColor(event.event))
                                .frame(width: 14)

                            Text(eventLabel(event.event))
                                .font(.caption)
                                .foregroundColor(.primary)

                            if let tool = event.tool {
                                Text(tool)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(formatTime(event.timestamp))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)

                        if index < filtered.count - 1 {
                            Divider().opacity(0.3).padding(.horizontal, 8)
                        }
                    }
                }
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .cornerRadius(8)
            }
        }
    }

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "活跃会话 (\(sessionManager.sessions.count))", accent: .green)

            VStack(spacing: 3) {
                ForEach(
                    Array(sessionManager.sessions.values)
                        .sorted(by: { $0.lastEventTime > $1.lastEventTime })
                ) { session in
                    let isActive = session.id == sessionManager.activeSessionId
                    HStack(spacing: 0) {
                        if isActive {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.accentColor)
                                .frame(width: 3)
                                .padding(.vertical, 4)
                        }
                        HStack(spacing: 8) {
                            Text(session.projectName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            StateBadge(state: session.state, compact: true)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    }
                    .background(
                        isActive
                            ? Color.accentColor.opacity(0.12)
                            : Color.white.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sessionManager.selectSession(session.id)
                    }
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() }
                        else { NSCursor.pop() }
                    }
                }
            }
        }
    }

    private func eventIcon(_ event: String) -> String {
        switch event {
        case "SessionStart": return "play.circle.fill"
        case "SessionEnd": return "stop.circle.fill"
        case "UserPromptSubmit": return "text.bubble.fill"
        case "PostToolUse": return "checkmark.circle.fill"
        case "PostToolUseFailure": return "xmark.circle.fill"
        case "Stop": return "flag.checkered"
        default: return "circle.fill"
        }
    }

    private func eventColor(_ event: String) -> Color {
        switch event {
        case "SessionStart": return .green
        case "SessionEnd": return .gray
        case "UserPromptSubmit": return .blue
        case "PostToolUse": return .green
        case "PostToolUseFailure": return .red
        case "Stop": return .orange
        default: return .secondary
        }
    }

    private func eventLabel(_ event: String) -> String {
        switch event {
        case "SessionStart": return "会话开始"
        case "SessionEnd": return "会话结束"
        case "UserPromptSubmit": return "提交指令"
        case "PostToolUse": return "工具完成"
        case "PostToolUseFailure": return "工具失败"
        case "Stop": return "任务完成"
        default: return event
        }
    }

    private func formatTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func duration(since date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(seconds % 60)s" }
        return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
    }
}

// MARK: - StateBadge

private struct StateBadge: View {
    let state: PetState
    var compact: Bool = false

    var body: some View {
        Text(label)
            .font(compact ? .system(size: 9, weight: .medium) : .system(size: 10, weight: .medium))
            .foregroundColor(foreground)
            .padding(.horizontal, compact ? 5 : 7)
            .padding(.vertical, compact ? 1 : 2)
            .background(background)
            .cornerRadius(4)
    }

    private var label: String {
        switch state {
        case .sleeping: return "休眠"
        case .awake: return "空闲"
        case .thinking: return "思考中"
        case .working: return "执行中"
        case .celebrating: return "完成"
        case .error: return "出错"
        case .knocking: return "等待确认"
        }
    }

    private var foreground: Color {
        switch state {
        case .sleeping: return .gray
        case .awake: return .green
        case .thinking: return .blue
        case .working: return .orange
        case .celebrating: return Color(red: 0.7, green: 0.6, blue: 0)
        case .error: return .red
        case .knocking: return .purple
        }
    }

    private var background: Color {
        foreground.opacity(0.12)
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let title: String
    var accent: Color = .secondary

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accent)
                .frame(width: 3, height: 10)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 2)
    }
}
