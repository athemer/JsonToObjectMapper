//
//  CodeFactory.swift
//  Json2ObjectMapper
//
//  Created by kuanhuachen on 2018/5/26.
//  Copyright © 2018年 athemer. All rights reserved.
//

import Foundation

struct Properties {
    
    var name: String
    var type: String
    var prefix: [String] = []
    var isDate: Bool
    
    func code() -> String
    {
        if isDate {
            return prefix.joined(separator: " ") + " \(name)" + ": " + "Date?"
        } else {
            return prefix.joined(separator: " ") + " \(name)" + ": " + "String = \"\""
        }
        
    }
    
}

class Statement {
    
    var type: String?
    var statements: [String] = []
    
    func code() -> String
    {
        return  statements.joined(separator: "\n")
    }
    
}

struct Methods {
    var name: String
    var retrunType: String
    var prefix: [String] = []
    var parameters: [(String,String)] = []
    var statements: [String] = []
    
    func code() -> String
    {
        
        let returnString = retrunType.count > 0 ? " -> \(retrunType) " : ""
        
        var para  = self.parameters
        
        let parameterString = CodeFactory.generateDictionary(lines: &para).joined(separator: ", ")
        // (name: String, user_id: String)
        
        let define = prefix.joined(separator: " ") + " " + name + "(\(parameterString))" + returnString
        // private func someMethod(name: String, user_id: String) ->
        
        var lines = statements
        
        // 寫 inout 去在同樣的 memory address 變動 lines (加大括號)
        CodeFactory.wrapWithBrace(lines: &lines)
        
        let body = lines.joined(separator: "\n")
        /*
            {
                method statement
                method statement
                method statement
            }                       */
        
        return  define + " " + body
    }
}

class StructDefine {
    
    var typeName: String { return Keywords.struct.rawValue }
    var name: String
    var parent: StructDefine?
    
    var properties: [Properties] = []
    var methods: [Methods] = []
    
    
    @discardableResult
    func add(property p: Properties) -> Bool
    {
        properties.append(p)
        return true
    }
    
    @discardableResult
    func add(mothod m: Methods) -> Bool
    {
        methods.append(m)
        return true
    }
    
    init(_ name: String)
    {
        self.name = name
    }
    
    func code() -> String?
    {
        let classDefine = typeName + " " + name + ": Object, Mappable"

        // properties
        let propertylines = CodeFactory.generateProperties(lines: &properties)
        // methods
        let methodslines = CodeFactory.generateMethods(lines: &methods)
        
        var bodyLines = propertylines + methodslines
        
        CodeFactory.wrapWithBrace(lines: &bodyLines)
        
        let body = bodyLines.joined(separator: "\n")
        
        let imports = "import Foundation \nimport RealmSwift \nimport ObjectMapper\n\n"
        
        // class SomeClass: someParentClass { body }
        return imports + classDefine + " " + body
    }
}

class ClassDefine : StructDefine
{
    override var typeName: String { return Keywords.class.rawValue }
}


class CodeFactory {
    
    class func wrapWithBrace(lines: inout [String]) -> Void
    {
        lines.append("}")
        lines.insert("{", at: 0)
        return
    }
    
    class func generateDictionary(lines: inout [(String,String)] ) -> [String]
    {
        return lines.map { (name, type) -> String in
            return name + ": " + type
        }
    }
    
    class func generateProperties(lines: inout [Properties]) -> [String]
    {
        return lines.map { (line) -> String in
            return line.code()
        }
    }
    
    class func generateMethods(lines: inout [Methods]) -> [String]
    {
        return lines.map { (line) -> String in
            return line.code()
        }
    }
}
