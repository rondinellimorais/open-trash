//
//  Trash.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Foundation

struct Directory {
	var Trash = "\(NSHomeDirectory())/.Trash"
}

protocol TrashDelegate : NSObjectProtocol {
	func statusTrashDidChanged(_ status:StatusTrash)
	func trashDidClean()
}

class Trash : NSObject {
	
	static let shared = Trash()
	public var delegate:TrashDelegate?
	
	var status:StatusTrash = StatusTrash.None
	var currentStatusContent:StatusContentTrash = StatusContentTrash.None
	
	var statusTimer:Timer?
	var statusContentTimer:Timer?
	
	override init() {
		super.init()
		
		self.checkStatus(nil)
		self.checkStatusContent(nil)
		
		cleanTimers()
		createTimers()
	}
	
	func cleanTimers() {
		if self.statusTimer != nil {
			self.statusTimer?.invalidate()
			self.statusTimer = nil
		}
		
		if self.statusContentTimer != nil {
			self.statusContentTimer?.invalidate()
			self.statusContentTimer = nil
		}
	}
	
	func createTimers() {
		self.statusTimer = Timer.scheduledTimer(timeInterval: 0.5,
																						target:self,
																						selector: #selector(checkStatus(_:)),
																						userInfo: nil,
																						repeats: true)
		
		self.statusContentTimer = Timer.scheduledTimer(timeInterval: 0.5,
																									 target:self,
																									 selector: #selector(checkStatusContent(_:)),
																									 userInfo: nil,
																									 repeats: true)
	}
	
	/**
	* Se a janela do finder ativa for da lixeira, retorna o status de aberto,
	* caso contrário
	* retorna o status de fechado
	*/
	func statusDirectory() -> StatusTrash {
		let command = NSMutableString()
		command.append(" tell application \"Finder\" \n")
		command.append("      return POSIX path of (target of window 1 as alias) \n")
		command.append(" end tell ")
		
		let script = NSAppleScript(source: command as String)
		var errors:NSDictionary?
		let descriptor = script?.executeAndReturnError(&errors) as NSAppleEventDescriptor?
		
		if ((errors == nil) || (descriptor != nil)) {
			let path = descriptor?.stringValue
			
			if path != nil {
				
				if let _ = path?.range(of: Directory().Trash) {
					return StatusTrash.Opened
				}
			}
		}
		return StatusTrash.Closed
	}
	
	/**
	* Se o diretório da lixeira estiver vazia, retorna o status de vazio
	* caso contrário retorna não vazio
	*/
	func statusContentsDirectory() -> StatusContentTrash? {
		let contents = try! FileManager().contentsOfDirectory(atPath: Directory().Trash)
		if contents.isEmpty {
			return StatusContentTrash.Emptied
		}
		return StatusContentTrash.NotEmpty
	}
	
	@objc private func checkStatus(_ timer:Timer!) {
		
		let statusTrash = self.statusDirectory()
		
		if statusTrash != self.status {
			self.status = statusTrash
			self.delegate?.statusTrashDidChanged(statusTrash)
		}
	}
	
	@objc private func checkStatusContent(_ timer:Timer!) {
		
		if let statusContent = self.statusContentsDirectory() {
			if self.currentStatusContent == StatusContentTrash.NotEmpty && statusContent == StatusContentTrash.Emptied {
				 self.delegate?.trashDidClean()
			}
			self.currentStatusContent = statusContent
		}
	}
}
