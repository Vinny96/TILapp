//
//  File.swift
//  
//
//  Created by Vinojen Gengatharan on 2021-04-24.
//

import Vapor
import Fluent

// 1
final class Acronym : Model{
    
    //2
    static let schema = "acronyms"
    
    //3
    @ID
    var id: UUID?
    
    //4
    @Field(key : "short")
    var short : String
    
    @Field(key: "long")
    var long : String
    
    // 5
    init(){}
    
    //6
    init(id : UUID? = nil, short : String, long : String) {
        self.id = id
        self.short = short
        self.long = long
        print("Testing")
    }
}

extension Acronym : Content
{
    
}
