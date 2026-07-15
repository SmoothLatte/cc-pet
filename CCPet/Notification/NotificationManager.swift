import AppKit
import SwiftUI

@MainActor
final class NotificationManager: ObservableObject {
    @Published var taskCompleteEnabled = true
    @Published var errorAlertEnabled = true
    @Published var sessionEndEnabled = true

    private var bubbleWindow: BubbleWindow?
    private var dismissTask: Task<Void, Never>?

    weak var petWindowController: PetWindowController?

    func requestAuthorization() {}

    func notifyIfNeeded(event: HookEvent, projectName: String, failureCount: Int) {
        switch event.event {
        case "Stop" where taskCompleteEnabled:
            showBubble(title: "任务完成", message: projectName, style: .success)
        case "PostToolUseFailure" where errorAlertEnabled && failureCount >= 3:
            showBubble(title: "执行出错", message: projectName, style: .error)
        case "SessionEnd" where sessionEndEnabled:
            showBubble(title: "会话结束", message: projectName, style: .info)
        default:
            break
        }
    }

    private func showBubble(title: String, message: String, style: BubbleStyle) {
        dismissTask?.cancel()
        bubbleWindow?.orderOut(nil)

        let bubble = BubbleWindow()
        let view = BubbleView(title: title, message: message, style: style)
        bubble.contentView = NSHostingView(rootView: view)

        if let petFrame = petWindowController?.petWindowFrame {
            let x = petFrame.midX - 130
            let y = petFrame.maxY + 8
            bubble.setFrameOrigin(NSPoint(x: x, y: y))
        }

        bubble.alphaValue = 0
        bubble.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            bubble.animator().alphaValue = 1
        }

        self.bubbleWindow = bubble

        dismissTask = Task { @MainActor in
            let duration = UserDefaults.standard.double(forKey: "bubbleDuration")
            let seconds = duration > 0 ? duration : 3.0
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                bubble.animator().alphaValue = 0
            }, completionHandler: {
                bubble.orderOut(nil)
            })
        }
    }
}
