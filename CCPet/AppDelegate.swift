import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var petWindowController: PetWindowController?
    private let sessionManager = SessionManager()
    let notificationManager = NotificationManager()
    private var socketServer: SocketServer?
    private var celebrationTimer: Timer?
    private var errorTimer: Timer?
    private var knockingTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        notificationManager.requestAuthorization()

        let socketPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".cc-pet/pet.sock")

        socketServer = SocketServer(socketPath: socketPath) { [weak self] event in
            await self?.handleEvent(event)
        }
        do {
            try socketServer?.start()
        } catch {
            print("[cc-pet] Failed to start socket server: \(error)")
        }

        petWindowController = PetWindowController(
            sessionManager: sessionManager,
            notificationManager: notificationManager
        )
        notificationManager.petWindowController = petWindowController

        setupTimeoutTimers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        petWindowController?.savePosition()
        socketServer?.stop()
    }

    private func handleEvent(_ event: HookEvent) {
        sessionManager.handleEvent(event)

        let projectName = sessionManager.sessions[event.sessionId]?.projectName ?? "Unknown"
        let failures = sessionManager.consecutiveFailures(for: event.sessionId)
        notificationManager.notifyIfNeeded(
            event: event,
            projectName: projectName,
            failureCount: failures
        )

        if event.event == "PreToolUse" {
            knockingTimer?.invalidate()
            knockingTimer = nil
            let autoApprovedTools: Set<String> = [
                "Bash", "Read", "Edit", "Write", "MultiEdit",
                "Glob", "Grep", "LS", "NotebookRead", "NotebookEdit",
                "WebFetch", "WebSearch", "TodoWrite", "Agent"
            ]
            let toolName = event.tool ?? ""
            if !autoApprovedTools.contains(toolName) {
                let sid = event.sessionId
                knockingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if self.sessionManager.sessions[sid]?.state == .working {
                            self.sessionManager.sessions[sid]?.state = .knocking
                        }
                    }
                }
            }
        }
        if ["PostToolUse", "PostToolUseFailure", "Stop", "SessionEnd"].contains(event.event) {
            knockingTimer?.invalidate()
            knockingTimer = nil
        }

        if event.event == "Stop" {
            celebrationTimer?.invalidate()
            celebrationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    if self?.sessionManager.sessions[event.sessionId]?.state == .celebrating {
                        self?.sessionManager.sessions[event.sessionId]?.state = .awake
                    }
                }
            }
        }
        if event.event == "PostToolUseFailure" {
            errorTimer?.invalidate()
            errorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    if self?.sessionManager.sessions[event.sessionId]?.state == .error {
                        self?.sessionManager.sessions[event.sessionId]?.state = .awake
                    }
                }
            }
        }
    }

    private func setupTimeoutTimers() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let threshold = Date().addingTimeInterval(-600)
                for (id, session) in self.sessionManager.sessions {
                    if session.state != .sleeping && session.lastEventTime < threshold {
                        self.sessionManager.sessions[id]?.state = .sleeping
                    }
                }
            }
        }
    }
}
