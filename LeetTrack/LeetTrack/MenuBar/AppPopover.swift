//
//  AppPopover.swift
//  
//
//  Created by Alexander Ajagba on 7/7/25.
//
import SwiftUI
import Charts


class AppPopover : NSObject, NSPopoverDelegate {
    private var popover: NSPopover!
    // initalizer popover as content view and state as parameters
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
}

