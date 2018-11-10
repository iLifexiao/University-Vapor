//
//  LostAndFoundController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class LostAndFoundController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "lostandfound")
        group.get("all", use: getAllHandler)
        group.get(LostAndFound.parameter, use: getHandler)
        
        group.post(LostAndFound.self, use: createHandler)
        group.patch(LostAndFound.parameter, use: updateHandler)
        group.delete(LostAndFound.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension LostAndFoundController {
    func getAllHandler(_ req: Request) throws -> Future<[LostAndFound]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LostAndFound.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<LostAndFound> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LostAndFound.self)
    }
    
    func createHandler(_ req: Request, lostAndFound: LostAndFound) throws -> Future<LostAndFound> {
        _ = try req.requireAuthenticated(APIUser.self)
        lostAndFound.createdAt = Date().timeIntervalSince1970
        return lostAndFound.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<LostAndFound> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: LostAndFound.self, req.parameters.next(LostAndFound.self), req.content.decode(LostAndFound.self)) { lostAndFound, newLostAndFound in
            lostAndFound.imageURL = newLostAndFound.imageURL
            lostAndFound.title = newLostAndFound.title
            lostAndFound.content = newLostAndFound.content
            lostAndFound.time = newLostAndFound.time
            lostAndFound.site = newLostAndFound.site
            lostAndFound.updatedAt = Date().timeIntervalSince1970
            return lostAndFound.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LostAndFound.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[LostAndFound]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return LostAndFound.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)
            or.filter(\.site == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[LostAndFound]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LostAndFound.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

