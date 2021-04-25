//
//  File.swift
//  
//
//  Created by Vinojen Gengatharan on 2021-04-24.
//

import Fluent

// 1 here we are defining a new type which is CreateAcronym and this conforms to migration
struct CreateAcronym : Migration {
    
    // 2 Implement prepare(on:) as required by Migration. You call this method when you run your migrations
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // 3 Define the table name for this model. This must match schema from the model.
        database.schema("acronyms")
            //4 Define the ID column in the database
            .id()
            // 5 Define columns for short and long. Set the column type to string and mark the columns as required. This matches the non-optional String properties in the model which again are in Acronym.swift. The field names must match the key of the property wrapper, not the name of the property itself. The field names have to match the names we put in @Field and we have two of these. So the field names we create have to match both of keys of the proprety wrappers. 
            .field("short", .string, .required)
            .field("long", .string, .required)
            // 6
            .create()
    }
    
    // 7
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronyms").delete()
    }
}
