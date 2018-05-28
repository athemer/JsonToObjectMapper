//
//  ModelFactory.swift
//  Json2ObjectMapper
//
//  Created by kuanhuachen on 2018/5/26.
//  Copyright © 2018年 athemer. All rights reserved.
//

import Foundation
import SwiftyJSON

let modelSubfix = "Model"
let viewModelSubfix = "Model"

class ModelFactory: ClassFactory  {
    
    var viewModel: ClassDefine?
    var nestClass: [String] = []
    var mappableFuncBody: [String] = []
    
    let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return formatter
    }()
    
    init(superClass: StructDefine, name: String)
    {
        viewModel = ClassDefine( name + modelSubfix )
        
        super.init()
        
        self.superClass = superClass
        
        self.selfClass = StructDefine( name + modelSubfix )
        
        self.selfClass?.parent = superClass
        
    }
    
    convenience init(superClass: String, name: String)
    {
        self.init(superClass: StructDefine(superClass), name: name)
    }
    
    fileprivate func visit(_ json: JSON, nestkey: String? = nil) {
        
        switch json.type
        {
        case .dictionary:
            
            //先加 extension conform to Mappable
            if let nestkey = nestkey
            {
                
                let model = ModelFactory(superClass: superClass!, name: nestkey)
                
                let modelCode = model.generateModel(json: json)
                
                // 加上子 model
                nestClass.append(modelCode)
                return
            }
            
            
            
            for (key, value) in json.dictionary!
            {
                
                var property: Properties?
                
                if dateFormatter.date(from: value.string ?? "") != nil || key.contains("date") {
                    
                    property = Properties(name: key,
                                          type: value.type.optionalType(key: key + modelSubfix),
                                          prefix: ["   ", Keywords.dynamic.rawValue, Keywords.var.rawValue],
                                          isDate: true)
                    
                    let body = "    \(key) = mappingDate(date: \(key), map: map[\"\(key)\"], dateFormat: DateFormatterType.DATE_TO_SECONDS.rawValue)"
                    mappableFuncBody.append(body)

                    
                } else {
                    
                    property = Properties(name: key,
                                          type: value.type.optionalType(key: key + modelSubfix),
                                          prefix: ["   ", Keywords.dynamic.rawValue, Keywords.var.rawValue],
                                          isDate: false)
                    
                    let body = "    \(key) = mappingString(map: map[\"\(key)\"])"
                    mappableFuncBody.append(body)

                }
            
                viewModel?.add(property: property!)
                visit(value, nestkey: key)
                
            }
            
            let primaryKeyFunc = Methods(name: "\(Keywords.override.rawValue) \(Keywords.static.rawValue) func primaryKey",
                retrunType: "String",
                prefix: [],
                parameters: [],
                statements: ["return \"id\""])
            
            self.viewModel?.add(mothod: primaryKeyFunc)
            
        // 若有 array 時需要創建子 model
        case .array:
            
            if let nestkey = nestkey
            {
                if let value = json.array?.first
                {
                    
                    let model = ModelFactory(superClass: superClass!, name: nestkey)
                    
                    let modelCode = model.generateModel(json: value)
                    
                    nestClass.append(modelCode)
                }
            }
            
        default:
            print(" - @@@@ - \(json.type) -- \(json) ")
            
        }
        
    }
    
    func generateModel(path: String, destination: String) {
    
        guard
            let fileUrl = URL(string: path)
            else { return }
        
        do
        {
            
            let data = try Data(contentsOf: fileUrl)
            let json = try JSON(data: data)
            visit(json)
            
        } catch (let e) {
            
            print(e)
            
        }
        
        let r = selfClass?.code()
        
        let fileUrl1 = URL(string: destination + (self.selfClass?.name)! + ".swift")
        
        try? r?.write(to: fileUrl1!, atomically: true, encoding: String.Encoding.utf8)
        
        /*
         required convenience init?(map: Map) {
         self.init()
         mapping(map: map)
         }
         
         override static func primaryKey() -> String {
         return "doc_id"
         }
         */
        

        let requiredInitFunc = Methods(name: "\(Keywords.required.rawValue) \(Keywords.convenience.rawValue) init?",
            retrunType: "",
            prefix: [],
            parameters: [("map", "Map")],
            statements: ["self.init()", "mapping(map: map)"])
        
        self.viewModel?.add(mothod: requiredInitFunc)
        
        let mappablefunc = Methods(name: "func mapping",
                                   retrunType: "",
                                   prefix: [],
                                   parameters: [("map", "Map")],
                                   statements: mappableFuncBody)
        
        self.viewModel?.add(mothod: mappablefunc)

        
        
        let viewModelcode = self.viewModel?.code()
        
        let fileUrlviewModel = URL(string: destination + (self.viewModel?.name)!  + ".swift")
        
        try? viewModelcode?.write(to: fileUrlviewModel!, atomically: true, encoding: String.Encoding.utf8)
    }
    
    func generateModel(jsonStr: String, needViewModel: Bool = false) -> String
    {
        
        let json = JSON(parseJSON: jsonStr)
        
        return generateModel(json: json,
                             needViewModel: needViewModel)
    }
    
    func generateModel(json: JSON, needViewModel: Bool = false) -> String
    {
        
        visit(json)
        
        let code = selfClass?.code()
        let codes = [code!] + nestClass
        let allcode = codes.joined(separator: "\n")
        
        if needViewModel {
            
            /*
             required convenience init?(map: Map) {
             self.init()
             mapping(map: map)
             }
             
             override static func primaryKey() -> String {
             return "doc_id"
             }
             */
            
            let requiredInitFunc = Methods(name: "\(Keywords.required.rawValue) \(Keywords.convenience.rawValue) init?",
                                           retrunType: "",
                                           prefix: [],
                                           parameters: [("map", "Map")],
                                           statements: ["   self.init()", "     mapping(map: map)"])

            
            let primaryKeyFunc = Methods(name: "\(Keywords.override.rawValue) \(Keywords.static.rawValue) func",
                                         retrunType: "String",
                                         prefix: [],
                                         parameters: [],
                                         statements: ["     return someFakedPrimaryKeyForNow"])
            
            self.viewModel?.add(mothod: requiredInitFunc)
            self.viewModel?.add(mothod: primaryKeyFunc)
            
            let viewModelcode = self.viewModel?.code()
            
            return allcode + "\n" + viewModelcode!
        }
        
        return allcode
    }
}



extension Type {

    func rawType(key:String) -> String
    {
        switch self
        {
        case .array:
            return "[\(key)]"
        case .dictionary:
            return key
        case .bool:
            return Keywords.Bool.rawValue
        case .number:
            return Keywords.Int.rawValue
        case .string:
            return Keywords.String.rawValue
        default:
            return "Any"
        }
    }

    func optionalType(key:String) -> String
    {
        switch self
        {
        case .array:
            let code = TypeDefine.optional(.custom(name: key)).code()
            return "[\(code)]"
        case .dictionary:
            return key
        case .bool:
            return TypeDefine.optional(.Bool).code()
        case .number:
            return TypeDefine.optional(.Int).code()
        case .string:
            return TypeDefine.optional(.String).code()
        default:
            return TypeDefine.optional(.Any).code()
        }
    }
}
