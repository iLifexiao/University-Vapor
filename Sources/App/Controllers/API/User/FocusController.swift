//
//  FocusController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class FocusController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "focus")
        group.get("all", use: getAllHandler)
        group.get(Focus.parameter, use: getHandler)
        
        group.post(Focus.self, use: createHandler)
        group.delete(Focus.parameter, use: deleteHandler)
        
        group.get("sort", use: sortedHandler)
    }
    
}

extension FocusController {
    func getAllHandler(_ req: Request) throws -> Future<[Focus]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Focus.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Focus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Focus.self)
    }
    
    func createHandler(_ req: Request, focus: Focus) throws -> Future<Focus> {
        _ = try req.requireAuthenticated(APIUser.self)
        focus.createdAt = Date().timeIntervalSince1970
        focus.status = 1
        return focus.save(on: req)
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Focus.self).delete(on: req).transform(to: .ok)
    }
       
    func sortedHandler(_ req: Request) throws -> Future<[Focus]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Focus.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

