//
//  AppDelegate.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Cocoa
import IOBluetooth

@NSApplicationMain
class AppDelegate: NSObject {
	
	var activeWindow:NSWindowController?
	let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
	var rfcommChannel: IOBluetoothRFCOMMChannel?
	var mBluetoothDevice:IOBluetoothDevice?
	var mRFCOMMChannel:IOBluetoothRFCOMMChannel?
	var statusTrashDidChange:((_ status: StatusTrash) -> Void)?
	
	func constructMenu() {
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "Main View", action: #selector(AppDelegate.openMainWindow(_:)), keyEquivalent: ""))
		menu.addItem( NSMenuItem.separator() )
		menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
		statusItem.menu = menu
	}
	
	func startMonitor(){
		
		// start status trash monitor
		Trash.shared.delegate = self
	}
	
	func sendBluetoothData(_ signal: String) {

		let writebuffer = NSMutableData()
		writebuffer.setData(signal.data(using: String.Encoding.ascii)!)
		
		if let rfcommChannel = self.rfcommChannel {
			rfcommChannel.writeSync(writebuffer.mutableBytes, length: UInt16(writebuffer.length))
		}
	}
	
	@objc func openMainWindow(_ sender: Any?) {
		
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
	
	@objc func closeDeviceConnectionOnDevice(_ device:IOBluetoothDevice) {
		
		if ( self.mBluetoothDevice == device )
		{
			if let error:IOReturn  = mBluetoothDevice?.closeConnection(), error != kIOReturnSuccess {
				// I failed to close the connection, maybe the device is busy, no problem, as soon as the device is no more busy it will close the connetion itself.
				print("Error - failed to close the device connection with error \(error).\n")
			}
			
			self.mBluetoothDevice = nil
		}
	}
	
	@objc func closeRFCOMMConnectionOnChannel(_ channel:IOBluetoothRFCOMMChannel){
		
		if self.mRFCOMMChannel == channel {
			self.mRFCOMMChannel?.close()
		}
	}
}

extension AppDelegate : NSApplicationDelegate {
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		if let button = statusItem.button {
			button.image = NSImage(named: NSImage.Name(rawValue: "trash_icon"))
		}
		
		constructMenu()
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		
		self.closeDeviceConnectionOnDevice(self.mBluetoothDevice!)
		
		self.closeRFCOMMConnectionOnChannel(self.mRFCOMMChannel!)
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
		
		sendBluetoothData(status.rawValue)
		
		// notify block
		if let block = self.statusTrashDidChange {
			block(status)
		}
	}
	
	func trashDidClean() {
		sendBluetoothData(StatusContentTrash.Emptied.rawValue)
	}
}

// https://www.raywenderlich.com/165853/menus-popovers-menu-bar-apps-macos
