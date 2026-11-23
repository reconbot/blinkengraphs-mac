import SwiftUI

@main
struct BlinkengraphsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    // A menu-bar app (LSUIElement): no window until Settings exists.
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = Monitor()
    private var statusBar: StatusBar?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBar(monitor: monitor)
        monitor.start()
    }
}
