//
//  AppDelegate.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject {
    
    var activeWindow:NSWindowController?
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Main View", action: #selector(AppDelegate.openMainWindow(_:)), keyEquivalent: ""))
        menu.addItem( NSMenuItem.separator() )
        menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func openMainWindow(_ sender: Any) {
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)

        let identifier = NSStoryboard.SceneIdentifier(rawValue: "MainWindow")

        guard let viewController = storyboard.instantiateController(withIdentifier: identifier) as? NSWindowController else {
            fatalError("Why cant i find ViewController? - Check Main.storyboard")
        }

        viewController.window?.delegate = self
        
        viewController.showWindow(self)
        
        if let activeWindow = self.activeWindow {
            activeWindow.close()
        }
        
        self.activeWindow = viewController
    }
}

extension AppDelegate : NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(rawValue: "trash_icon"))
        }
        
        constructMenu()
        
        // start status trash monitor
        Trash.shared.delegate = self
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate : NSWindowDelegate {
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        
        if let activeWindow = self.activeWindow {
            activeWindow.close()
        }
        
        return true
    }
}

extension AppDelegate : TrashDelegate {
    
    func statusTrashDidChanged(_ status: StatusTrash) {
        
        // TODO: avisar o arduino via bluetooth
    }
}

// https://www.raywenderlich.com/165853/menus-popovers-menu-bar-apps-macos
