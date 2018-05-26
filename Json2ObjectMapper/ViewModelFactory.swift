//
//  ViewModelFactory.swift
//  Json2ObjectMapper
//
//  Created by kuanhuachen on 2018/5/26.
//  Copyright © 2018年 athemer. All rights reserved.
//

import Foundation

class ViewModelFactory : ClassFactory {
    
    var model : ModelFactory
    
    init(model: ModelFactory)
    {
        self.model = model
    }
    
    func genViewModel(destination: String) -> ()
    {
        
    }
    
}
