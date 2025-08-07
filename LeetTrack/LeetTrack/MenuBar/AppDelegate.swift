import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var appPopover: AppPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Set up the status bar item with a title
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(named: "leetcode_menubar") {
                image.isTemplate = true
                button.image = image
            } else {
                print("Failed to load image")
            }
            button.imagePosition = .imageOnly
        }
        
        appPopover = AppPopover(contentView: ContentView())

        // Button action to toggle the popover
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.target = self
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            appPopover.toggle(relativeTo: button, sender: sender)
        }
    }
}
