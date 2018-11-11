//
//  EssayController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class EssayController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "essay")
        group.get("all", use: getAllHandler)
        group.get(Essay.parameter, use: getHandler)
        
        group.post(Essay.self, use: createHandler)
        group.patch(Essay.parameter, use: updateHandler)
        group.delete(Essay.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension EssayController {
    func getAllHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Essay.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self)
    }
    
    func createHandler(_ req: Request, essay: Essay) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        essay.createdAt = Date().timeIntervalSince1970
        essay.status = 1
        essay.likeCount = 0
        essay.commentCount = 0
        essay.readCount = 0
        return essay.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Essay.self, req.parameters.next(Essay.self), req.content.decode(Essay.self)) { essay, newEssay in
            essay.title = newEssay.title
            essay.content = newEssay.content
            essay.type = newEssay.type
            essay.updatedAt = Date().timeIntervalSince1970
            return essay.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Essay.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Essay.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
