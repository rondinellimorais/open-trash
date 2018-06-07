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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Trash.shared.delegate = self
        
        self.changeLabelValues()
    }
    
    func changeLabelValues(){
        
        switch Trash.shared.status
        {
            case .Open:
                self.statusTrashTextLabel.stringValue = "Lixeira aberta!"
                self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 78/255, green: 200/255, blue: 79/255, alpha: 1)
            
            case .Close:
                self.statusTrashTextLabel.stringValue = "Lixeira fechada!"
                self.statusTrashTextLabel.textColor = NSColor.red
                self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 219/255, green: 58/255, blue: 49/255, alpha: 1)
            
            default:break
        }
    }
}

extension ViewController : TrashDelegate {
    
    func statusTrashDidChanged(_ status: StatusTrash) {
        self.changeLabelValues()
    }
}
