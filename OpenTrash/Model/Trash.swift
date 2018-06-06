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

class Trash : NSObject {
    
    //------------------------------------------------------------
    // Methods
    //------------------------------------------------------------
    func status() -> StatusTrash {
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
}
