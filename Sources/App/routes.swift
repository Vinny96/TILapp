import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    //1 Register a new route at /api/acronyms/ that accepts  a POST request and returns EventLoopFuture<Acronym>
    app.post("api","acronyms"){ req -> EventLoopFuture<Acronym> in
    //2 Decode the request's JSON into an Acronym. This can be done beecause acronym conforms to Content.
        let acronym = try req.content.decode(Acronym.self)
    //3 Save the model using Fluent. When the save completes, you return the model inside the completion handler for map(_:). This returns an EventLoopFuture in this case, EventLoopFuture<Acronym>
        return acronym.save(on: req.db).map {
            // 4
            acronym
        }
    }
    
    // 1 Register a new route handler that accepts a GET request which returns EventLoopFuture<[Acronym]>, a future array of Acronym.
    app.get("api","acronyms"){
        req -> EventLoopFuture<[Acronym]> in
        // 2 Perform a query to get all the acronyms. 
        Acronym.query(on: req.db).all()
    }
    
    
    // 1 Register a route at /api.acronyms/<ID> to handle a GET request. The route takes a the acronym's id property as the final path segnment. This returns EvenLoopFuture<Acronym>.
    app.get("api","acronyms", ":acronymID"){
        req -> EventLoopFuture<Acronym> in
        // 2 Get the parameter passed in with the name acronymID. Use the find method to query the database for an Acronym with that id. The reason that this method takes a UUID as the first parmeter is because acronym's id type is UUID.
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
        // 3 this method returns EventLoopFuture<Acronym?> because an acronym with that ID might not exist in the database. We use unwrap(or:) to ensure that we return at acronym. If no acronym is found, unwrap(or:) returns a failed future with the error provided. In this case it returns a 404 Not Found error.
            .unwrap(or: Abort(.notFound))
    }
    

    app.put("api","acronyms",":acronymID"){
        req -> EventLoopFuture<Acronym> in

        let updatedAcronym = try req.content.decode(Acronym.self)
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { acronym in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                return acronym.save(on: req.db).map {
                    acronym
                }
            }
        /**
         So we first register a route for a PUT request to /api/acronyms/<ID> that returns EventLoopFuture<Acronym>.
         
         We then decode the request body to Acronym to get the new details
         
         We then get the acronym using the ID from the request URL. Use unwrap(or:)
         to return a 404 Not Found if no acronym with the ID is found. This returns EventLoopFuture<Acronym> so we use flat map to wait for the future to complete.
         
         We then update thea acronym's properites with the new values.
         
         We save the acronym and wait for it to compelte with map. Once the save has returned, we return the updated acronym.
        */
    }
    
    app.delete("api","acronyms",":acronymID"){
        req -> EventLoopFuture<HTTPStatus> in
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.delete(on: req.db)
                    .transform(to: .noContent)
            }
        /**
         So here we are registering a route for a DELETE request to /api/acronyms/<ID> that returns EventLoopFuture<HTTPStatus>.
         
         Extract the acronym to delete from the request's parameters as before
         
         Use FlatMap to wait for the acronym to return from the database.
         
         Delete the acronym useing delete(on:)
         
         Transform the result into a 204 no content reposnse. This tells the client the request has successfully completed but there's no content to return. 
         */
    }
    
    
    
}
