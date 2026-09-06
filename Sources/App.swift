import SwiftUI
import AppKit

@main
struct ScriptVoiceRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Window("Voiceover Studio", id: "studio") { StudioView(studio: delegate.studio) }
            .defaultSize(width: 1320, height: 760)
        Settings { StudioSettingsView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let studio = Studio()

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        studio.prepareToQuit() ? .terminateNow : .terminateCancel
    }
}
