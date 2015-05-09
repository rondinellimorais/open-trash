//
//  ViewController.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var statusTrashTextLabel: NSTextField!
    var statusTrash = StatusTrash.None

    override func viewDidLoad() {
        super.viewDidLoad()
        checkStatusTrash(nil)
        
        // verifica a cada 1s o status da lixeira
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target:self, selector: "checkStatusTrash:", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    // MARK: Private methods
    func checkStatusTrash(timer:NSTimer!) {
        
        var trash = Trash()
        
        var currentStatusTrash = trash.status()
        
        if currentStatusTrash != statusTrash
        {
            statusTrash = currentStatusTrash
            switch statusTrash
            {
            case .Open:
                self.statusTrashTextLabel.stringValue = "Lixeira aberta!"
                self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 78/255, green: 200/255, blue: 79/255, alpha: 1)
                
            case .Close:
                self.statusTrashTextLabel.stringValue = "Lixeira fechada!"
                self.statusTrashTextLabel.textColor = NSColor.redColor()
                self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 219/255, green: 58/255, blue: 49/255, alpha: 1)
                
            default:break
            }
        }
    }
}

