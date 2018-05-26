//
//  ViewController.swift
//  Json2ObjectMapper
//
//  Created by kuanhuachen on 2018/5/26.
//  Copyright © 2018年 athemer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var transferButton: NSButtonCell!
    @IBOutlet weak var jsonPath: NSTextField!
    @IBOutlet weak var destinationPath: NSTextField!

    @IBOutlet weak var classNameTextField: NSTextField!
    @IBOutlet weak var baseNameTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        destinationPath.placeholderString = "請選擇目標路徑"
        jsonPath.placeholderString = "請選擇來源路徑"
        classNameTextField.placeholderString = "class 名稱"
        
    }
    
    override func awakeFromNib() {
        
    }
    
    @IBAction func genCode(_ sender: Any) {
        
        let model = ModelFactory(superClass: baseNameTextField.stringValue, name: classNameTextField.stringValue)
        
        model.generateModel(path: jsonPath.stringValue, destination: destinationPath.stringValue)
        
        NSWorkspace.shared.openFile(jsonPath.stringValue)
        
    }
    
    
    
    @IBAction func selectDestination(_ sender: Any) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK)
        {
            let path = openPanel.url?.absoluteString
            
            print("已選擇文件輸出路徑: \(String(describing: path))")
            
            destinationPath.stringValue = path!
        }
    }
    
    
    @IBAction func selectJson(_ sender: Any) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if(openPanel.runModal() == NSApplication.ModalResponse.OK)
        {
            let path = openPanel.url?.absoluteString
            
            print("已選擇文件輸入路徑: \(String(describing: path))")
            
            jsonPath.stringValue = path!
            
        } else {
            return
        }
        
    }

}

