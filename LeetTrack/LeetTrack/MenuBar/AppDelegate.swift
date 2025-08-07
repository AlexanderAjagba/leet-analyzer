import Foundation
import SwiftUI
import AppKit    // ← needed for NSStatusBar, NSImage, etc.

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var appPopover: AppPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Create the status‐bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // 2. Load your image (replace "MyMenuBarIcon" with your asset name)
            let icon = NSImage(resource: .image)
            icon.isTemplate = true            // so it adapts to light/dark mode
            button.image = icon               // ← assign it here
            button.imagePosition = .imageOnly
            
            // wire the button to call your toggle
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // initialize your popover
        appPopover = AppPopover(contentView: ContentView())
    }   // ← Make sure this brace closes applicationDidFinishLaunching

    // ← togglePopover stays exactly as you wrote it
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            appPopover.toggle(relativeTo: button, sender: sender)
        }
    }
}
