//
//  CollectionController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class CollectionController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "collection")
        group.get("all", use: getAllHandler)
        group.get(Collection.parameter, use: getHandler)
        
        group.post(Collection.self, use: createHandler)
        group.delete(Collection.parameter, use: deleteHandler)
                
        group.get("sort", use: sortedHandler)
    }
    
}

extension CollectionController {
    func getAllHandler(_ req: Request) throws -> Future<[Collection]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Collection> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Collection.self)
    }
    
    func createHandler(_ req: Request, collection: Collection) throws -> Future<Collection> {
        _ = try req.requireAuthenticated(APIUser.self)
        collection.createdAt = Date().timeIntervalSince1970
        return collection.save(on: req)
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Collection.self).delete(on: req).transform(to: .ok)
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Collection> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).first().map(to: Collection.self) { collection in
            guard let collection = collection else {
                throw Abort(.notFound)
            }
            return collection
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Collection]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

