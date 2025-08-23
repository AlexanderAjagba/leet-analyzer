import SwiftUI
import Charts


class AppPopover : NSObject, NSPopoverDelegate {
    private var popover: NSPopover!

    init <Content : View>(contentView: Content) {
        super.init()
        self.popover = NSPopover()
        self.popover.delegate = self
        self.popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    // toggle popover into view
//    func toggleButton(relativeTo button: NSStatusBarButton,
    func toggle(relativeTo button: NSStatusBarButton, sender: AnyObject?) {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
        
    func close() {
        popover.performClose(self)
    }
}


