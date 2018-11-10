//
//  IdleGoodController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class IdleGoodController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "idlegood")
        group.get("all", use: getAllHandler)
        group.get(IdleGood.parameter, use: getHandler)
        
        group.post(IdleGood.self, use: createHandler)
        group.patch(IdleGood.parameter, use: updateHandler)
        group.delete(IdleGood.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension IdleGoodController {
    func getAllHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return IdleGood.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(IdleGood.self)
    }
    
    func createHandler(_ req: Request, idleGood: IdleGood) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        idleGood.createdAt = Date().timeIntervalSince1970
        return idleGood.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: IdleGood.self, req.parameters.next(IdleGood.self), req.content.decode(IdleGood.self)) { idleGood, newIdleGood in
            idleGood.imageURLs = newIdleGood.imageURLs
            idleGood.title = newIdleGood.title
            idleGood.content = newIdleGood.content
            idleGood.originalPrice = newIdleGood.originalPrice
            idleGood.price = newIdleGood.price
            idleGood.type = newIdleGood.type
            idleGood.updatedAt = Date().timeIntervalSince1970
            return idleGood.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(IdleGood.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return IdleGood.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    
    func sortedHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return IdleGood.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
