//
//  Trash.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Foundation

enum StatusTrash {
    case Open
    case Close
    case None
}

struct Directory {
    var Trash = "\(NSHomeDirectory())/.Trash"
}

protocol TrashDelegate : NSObjectProtocol {
    func statusTrashDidChanged(_ status:StatusTrash)
}

class Trash : NSObject {
    
    static let shared = Trash()
    public var delegate:TrashDelegate?
    var status:StatusTrash = StatusTrash.None
    
    override init() {
        super.init()
        
        self.checkStatus(nil)
        
        Timer.scheduledTimer(timeInterval: 0.5, target:self, selector: #selector(checkStatus(_:)), userInfo: nil, repeats: true)
    }
    
    func statusBaseDirectory() -> StatusTrash {
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
                    return StatusTrash.Open
                }
            }
        }
        return StatusTrash.Close
    }
    
    @objc private func checkStatus(_ timer:Timer!) {
        
        let statusTrash = self.statusBaseDirectory()
        
        if statusTrash != self.status {
            self.status = statusTrash
            
            self.delegate?.statusTrashDidChanged(statusTrash)
        }
    }
}
