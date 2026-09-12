import AppKit
import SwiftUI

/// One action in a RightClickMenuOverlay menu.
struct ContextMenuAction {
    let title: String
    let systemImage: String?
    let enabled: Bool
    let handler: () -> Void

    init(_ title: String, systemImage: String? = nil, enabled: Bool = true, handler: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.handler = handler
    }
}

/// Shows a custom right-click menu over selectable text.
///
/// Text with .textSelection(.enabled) swallows right-clicks for its own (empty in a
/// table) menu, so a SwiftUI .contextMenu on the container never fires on the text
/// itself. This overlay claims only right-mouse events and lets every other event
/// fall through to the text below, so selection keeps working.
struct RightClickMenuOverlay: NSViewRepresentable {
    /// Rebuilt on every right-click, so items reflect current state.
    var actions: () -> [ContextMenuAction]

    func makeNSView(context: Context) -> RightClickMenuView {
        RightClickMenuView()
    }

    func updateNSView(_ view: RightClickMenuView, context: Context) {
        view.actions = actions
    }
}

final class RightClickMenuView: NSView {
    var actions: (() -> [ContextMenuAction])?

    /// All live overlays, so the event monitor can find the one under the cursor.
    private static var instances = NSHashTable<RightClickMenuView>.weakObjects()
    private static var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            Self.instances.add(self)
            Self.installMonitorIfNeeded()
        } else {
            Self.instances.remove(self)
        }
    }

    /// The table consumes the first right-click on an unselected row to change the
    /// selection before the event reaches this view, so the menu appeared only on an
    /// already-selected row. A local event monitor sees every right-click first and
    /// works even when the click activates an inactive window.
    private static func installMonitorIfNeeded() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            guard let window = event.window else { return event }
            for view in instances.allObjects where view.window == window && !view.isHiddenOrHasHiddenAncestor {
                let point = view.convert(event.locationInWindow, from: nil)
                guard view.bounds.contains(point), let actions = view.actions else { continue }
                view.showMenu(actions: actions, at: point)
                return nil
            }
            return event
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        NSApp.currentEvent?.type == .rightMouseDown ? self : nil
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let actions else { return }
        showMenu(actions: actions, at: convert(event.locationInWindow, from: nil))
    }

    func showMenu(actions: () -> [ContextMenuAction], at point: NSPoint) {
        let items = actions()
        guard !items.isEmpty else { return }
        let menu = NSMenu()
        var targets: [MenuActionTarget] = []
        for action in items {
            let target = MenuActionTarget(action.handler)
            let item = NSMenuItem(title: action.title, action: #selector(MenuActionTarget.run), keyEquivalent: "")
            item.target = target
            item.isEnabled = action.enabled
            if let systemImage = action.systemImage {
                item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
            }
            menu.addItem(item)
            targets.append(target)
        }
        // NSMenuItem.target is weak; keep targets alive for the duration of tracking.
        _ = withExtendedLifetime(targets) {
            menu.popUp(positioning: nil, at: point, in: self)
        }
    }
}

private final class MenuActionTarget: NSObject {
    let handler: () -> Void
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    @objc func run() { handler() }
}
