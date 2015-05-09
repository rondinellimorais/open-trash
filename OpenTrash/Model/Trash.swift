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
        var command = NSMutableString()
        command.appendString(" tell application \"Finder\" \n")
        command.appendString("      return POSIX path of (target of window 1 as alias) \n")
        command.appendString(" end tell ")
        
        var script = NSAppleScript(source: command)
        var errors:NSDictionary?
        var descriptor = script?.executeAndReturnError(&errors) as NSAppleEventDescriptor?
        
        if ((errors == nil) || (descriptor != nil)) {
            var path = descriptor?.stringValue
            
            if path != nil {
                
                var range = path?.rangeOfString(Directory().Trash,
                    options: NSStringCompareOptions.CaseInsensitiveSearch,
                    range: nil, locale: nil)
                
                if range != nil {
                    return StatusTrash.Open
                }
            }
        }
        return StatusTrash.Close
    }
}
