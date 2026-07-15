import AppKit
import SwiftUI

final class PetWindowController: NSWindowController {
    private let sessionManager: SessionManager
    private let notificationManager: NotificationManager
    private var popover: NSPopover?
    private var sizeObserver: Any?

    init(sessionManager: SessionManager, notificationManager: NotificationManager) {
        self.sessionManager = sessionManager
        self.notificationManager = notificationManager

        let savedFrame = Self.loadSavedFrame()
        let window = PetWindow(contentRect: savedFrame)

        super.init(window: window)

        let petView = PetView(sessionManager: sessionManager) { [weak self] in
            self?.toggleInfoPanel()
        }
        window.contentView = NSHostingView(rootView: petView)
        window.makeKeyAndOrderFront(nil)

        sizeObserver = UserDefaults.standard.observe(\.petSize, options: [.new]) { [weak self] _, change in
            guard let size = change.newValue, size > 0 else { return }
            DispatchQueue.main.async {
                self?.resizeWindow(to: size)
            }
        }
    }

    private func resizeWindow(to size: Double) {
        guard let window else { return }
        let origin = window.frame.origin
        window.setFrame(NSRect(x: origin.x, y: origin.y, width: size, height: size), display: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func toggleInfoPanel() {
        if let popover, popover.isShown {
            popover.close()
            self.popover = nil
            return
        }

        let panel = NSPopover()
        panel.contentSize = NSSize(width: 300, height: 380)
        panel.behavior = .transient
        panel.contentViewController = NSHostingController(
            rootView: InfoPanelView(sessionManager: sessionManager, notificationManager: notificationManager)
        )

        if let contentView = window?.contentView {
            panel.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
        self.popover = panel
    }

    var petWindowFrame: NSRect? {
        window?.frame
    }

    func savePosition() {
        guard let frame = window?.frame else { return }
        let dict: [String: CGFloat] = [
            "x": frame.origin.x,
            "y": frame.origin.y,
            "w": frame.width,
            "h": frame.height,
        ]
        let configDir = (NSHomeDirectory() as NSString).appendingPathComponent(".cc-pet")
        let configPath = (configDir as NSString).appendingPathComponent("config.json")
        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }

    private static func loadSavedFrame() -> NSRect {
        let configPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".cc-pet/config.json")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let dict = try? JSONDecoder().decode([String: CGFloat].self, from: data) {
            return NSRect(
                x: dict["x"] ?? 100,
                y: dict["y"] ?? 100,
                width: dict["w"] ?? 80,
                height: dict["h"] ?? 80
            )
        }
        return NSRect(x: 100, y: 100, width: 80, height: 80)
    }
}

extension UserDefaults {
    @objc dynamic var petSize: Double {
        double(forKey: "petSize")
    }
}
