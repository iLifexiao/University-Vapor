//
//  HonorController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class HonorController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "honor")
        group.get("all", use: getAllHandler)
        group.get(Honor.parameter, use: getHandler)
        
        group.post(Honor.self, use: createHandler)
        group.patch(Honor.parameter, use: updateHandler)
        group.delete(Honor.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension HonorController {
    func getAllHandler(_ req: Request) throws -> Future<[Honor]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Honor.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Honor> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Honor.self)
    }
    
    func createHandler(_ req: Request, honor: Honor) throws -> Future<Honor> {
        _ = try req.requireAuthenticated(APIUser.self)
        honor.createdAt = Date().timeIntervalSince1970
        return honor.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Honor> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Honor.self, req.parameters.next(Honor.self), req.content.decode(Honor.self)) { honor, newHonor in
            honor.name = newHonor.name
            honor.rank = newHonor.rank
            honor.time = newHonor.time
            honor.updatedAt = Date().timeIntervalSince1970
            return honor.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Honor.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Honor]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Honor.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.rank == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Honor]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Honor.query(on: req).sort(\.time, .ascending).all()
    }
}

