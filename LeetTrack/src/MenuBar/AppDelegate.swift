import Foundation
import SwiftUI
import AppKit    // ← needed for NSStatusBar, NSImage, etc.

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var appPopover: AppPopover!
    private var statusMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Create the status‐bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // right-click menu
        statusMenu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit LeetTrack", action: #selector(quitApp(_:)), keyEquivalent: "q")
        
        quitItem.target = self
        statusMenu.addItem(quitItem)
        
        if let button = statusItem.button {
            // 2. Load your image (replace "MyMenuBarIcon" with your asset name)
            let icon = NSImage(resource: .image)
            icon.isTemplate = true            // so it adapts to light/dark mode
            button.image = icon               // ← assign it here
            button.imagePosition = .imageOnly
            
            // wire the button to call your toggle
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusBarClicked(_:))
            button.target = self
        }
        
        // initialize your popover
        appPopover = AppPopover(contentView: PopoverHomeView())
    }   // ← Make sure this brace closes applicationDidFinishLaunching
    @objc private func statusBarClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {return}
        if event.type == .rightMouseUp {
            if let button = statusItem.button {
                statusMenu.popUp(positioning: nil, at: NSPoint(x:0, y: button.bounds.height + 4), in: button)
            }
        } else {
            appPopover.toggle(relativeTo: statusItem.button!, sender: sender as AnyObject)
        }
    }

    // ← togglePopover stays exactly as you wrote it
    @objc private func quitApp(_ sender: AnyObject?) {
        NSApp.terminate(nil)
    }
}
