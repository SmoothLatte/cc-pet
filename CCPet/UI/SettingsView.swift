import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @AppStorage("petSize") private var petSize: Double = 120
    @AppStorage("bubbleDuration") private var bubbleDuration: Double = 3.0
    @State private var hookInstalled = false
    @State private var installMessage = ""

    var body: some View {
        Form {
            Section("宠物") {
                HStack {
                    Text("大小: \(Int(petSize))pt")
                    Slider(value: $petSize, in: 60...500, step: 5)
                }

                Button("重置位置") {
                    NotificationCenter.default.post(name: .resetPetPosition, object: nil)
                }
            }

            Section("通知") {
                Toggle("任务完成通知", isOn: $notificationManager.taskCompleteEnabled)
                Toggle("执行出错通知", isOn: $notificationManager.errorAlertEnabled)
                Toggle("会话结束通知", isOn: $notificationManager.sessionEndEnabled)
                HStack {
                    Text("持续时间: \(String(format: "%.1f", bubbleDuration))秒")
                    Slider(value: $bubbleDuration, in: 1...10, step: 0.5)
                }
            }

            Section("Claude Code Hooks") {
                HStack {
                    Button(hookInstalled ? "重新安装 Hook" : "安装 Hook") {
                        installHooks()
                    }
                    if !installMessage.isEmpty {
                        Text(installMessage)
                            .font(.caption)
                            .foregroundColor(hookInstalled ? .green : .red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 320)
        .onAppear { checkHookStatus() }
    }

    private func checkHookStatus() {
        let settingsPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".claude/settings.json")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let content = String(data: data, encoding: .utf8),
           content.contains("cc-pet") {
            hookInstalled = true
        }
    }

    private func installHooks() {
        do {
            try HookInstaller.install()
            hookInstalled = true
            installMessage = "安装成功"
        } catch {
            installMessage = "安装失败: \(error.localizedDescription)"
        }
    }
}

extension Notification.Name {
    static let resetPetPosition = Notification.Name("resetPetPosition")
}

enum HookInstaller {
    static func install() throws {
        let petDir = (NSHomeDirectory() as NSString).appendingPathComponent(".cc-pet")
        try FileManager.default.createDirectory(atPath: petDir, withIntermediateDirectories: true)

        let hookScript = """
        #!/usr/bin/env node
        const net = require('net');
        const path = require('path');
        const os = require('os');
        const fs = require('fs');

        const SOCKET = path.join(os.homedir(), '.cc-pet', 'pet.sock');

        try { fs.statSync(SOCKET); } catch { process.exit(0); }

        let data = '';
        process.stdin.on('data', chunk => data += chunk);
        process.stdin.on('end', () => {
          try {
            const payload = JSON.parse(data);
            const event = {
              event: payload.hook_event_name || 'unknown',
              session_id: payload.session_id,
              cwd: payload.cwd,
              timestamp: Math.floor(Date.now() / 1000),
              ...(payload.tool_name && { tool: payload.tool_name }),
              ...(payload.tool_input && { tool_input: payload.tool_input }),
            };
            const client = net.createConnection(SOCKET, () => {
              client.end(JSON.stringify(event) + '\\n');
            });
            client.on('error', () => {});
            setTimeout(() => process.exit(0), 3000);
          } catch { process.exit(0); }
        });
        """
        let hookPath = (petDir as NSString).appendingPathComponent("hook.js")
        try hookScript.write(toFile: hookPath, atomically: true, encoding: .utf8)

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: hookPath
        )

        let settingsPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".claude/settings.json")
        var settings: [String: Any] = [:]

        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = json
        }

        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        let hookCommand = "node ~/.cc-pet/hook.js"
        let hookEntry: [String: Any] = [
            "hooks": [["type": "command", "command": hookCommand, "timeout": 5]]
        ]

        let eventTypes = [
            "SessionStart", "SessionEnd", "UserPromptSubmit",
            "PreToolUse", "PostToolUse", "PostToolUseFailure", "Stop",
        ]

        for eventType in eventTypes {
            var existing = hooks[eventType] as? [[String: Any]] ?? []
            let alreadyInstalled = existing.contains { entry in
                if let innerHooks = entry["hooks"] as? [[String: Any]] {
                    return innerHooks.contains { ($0["command"] as? String)?.contains("cc-pet") == true }
                }
                return false
            }
            if !alreadyInstalled {
                existing.append(hookEntry)
            }
            hooks[eventType] = existing
        }

        settings["hooks"] = hooks

        let outputData = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try outputData.write(to: URL(fileURLWithPath: settingsPath))
    }
}
