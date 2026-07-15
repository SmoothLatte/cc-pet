import SwiftUI

@main
struct CCPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(notificationManager: appDelegate.notificationManager)
        }
    }
}
