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
    
    app.get("api","acronyms","search"){
        req -> EventLoopFuture<[Acronym]> in
        guard let searchTerm = req.query[String.self, at : "term"] else {
            throw Abort(.badRequest)
        }
        /*return Acronym.query(on: req.db)
            .filter(\.$short == searchTerm)
            .all()*/
        return Acronym.query(on: req.db).group(.or){ or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
        /**
         Here is what is going on to search the acronyms
         1) Register a new route handler that accepts  a GET request for /api/acronyms/search and returns EventLoopFuture<[Acronym]>
         2) Retrieve the search term from the URL query string. If this fails, throw a 400 Bad Request error.
         3) User filter to find all acronms whose short property matches the searchTerm. Beccause this uses key paths, the compiler can enforce type-safety on teh properties and filter terms. This prevents run-time issues caused by specifying an invalid column name or invalid type to filter on. Fluent uses the property wrapper's projected value, instead of the value itself.
         
         Update so the updated code is now searching multiple fields so in this case both the short and long field. So to we added a filter to the group that will filter for acronyms whose short property matches the searchTerm and a filter for acronyms whose long property matches the searchTerm.
         
         
         */
    }
    
    app.get("api","acronyms","first"){
        req -> EventLoopFuture<Acronym> in
        Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
        
        /**
         This creates a new route HTTP Get route at /api/acronyms/first that retursn EventLoopFuture<Acronym>
          We then perform a query to get the first acronym. However first returns an optional as there may be no acronyms in teh database. That is why we use unwrap as this covers the case where if no acronyms exsit we throw a 404 not found error. 
         */
    }
    
    app.get("api","acronyms","sorted"){
        req -> EventLoopFuture<[Acronym]> in
        Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
        
        /**
        So here we are creating a new route handler at /api/acronyms/sorted that returns an EventLoopFuture<[Acronym]>
         
         So here we create a query for Acronym and we use the sort function to perform the sort. The keypath we provide to the property's wrapper is short and we also provide the direction to sort in which is ascending. We use all() to return all the results of the query.
         
         */
    }
    
    app.get("api","acronyms","sorted","first"){
        req -> EventLoopFuture<Acronym> in
        Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .first()
            .unwrap(or: Abort(.notFound))
        
        /**
         So here we are creating a route handler at /api/acronyms/sorted/first that returns an EventLoopFuture<Acronym>. We crete a query for Acronym and we perform a sort. The keypath we provide in is short and the sort order is ascending. We then want to get the first Acronym of the sorted results. We then use unwrap as there could be a chance that nothing is in the database and if in this case we throw a .notFound 404 error.
         */
    }
    
    
    app.get("api","acronyms","sorted","longDescending"){
        req -> EventLoopFuture<[Acronym]> in
        Acronym.query(on: req.db)
            .sort(\.$long,.descending)
            .all()
        
        /**
         So here we are creating a route handelr at /api/acronyms/sorted/longDescending that returns an EventLoopFuture<[Acronym]>. We then create a query on Acronym and the keypath we provide is long, the sort order is descending. We then return all the results.
         */
    }
    
    app.get("api","acronyms","sorted","longAscending"){
        req -> EventLoopFuture<[Acronym]> in
        Acronym.query(on: req.db)
            .sort(\.$long, .ascending)
            .all()
        
        /**
         We create a route handler at /api/acronyms/sorted/longAscending and this method returns an EventLoopFuture<[Acronym]>
         
         We then create a query on Acronym and the keypath we provide is long and the order is ascending. We then return all the results. 
         */
    }
    
}
