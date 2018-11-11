//
//  AcademicController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class AcademicController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "academic")
        group.get("all", use: getAllHandler)
        group.get(Academic.parameter, use: getHandler)
        
        group.post(Academic.self, use: createHandler)
        group.patch(Academic.parameter, use: updateHandler)
        group.delete(Academic.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension AcademicController {
    func getAllHandler(_ req: Request) throws -> Future<[Academic]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Academic.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Academic> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Academic.self)
    }
    
    func createHandler(_ req: Request, academic: Academic) throws -> Future<Academic> {
        _ = try req.requireAuthenticated(APIUser.self)
        academic.createdAt = Date().timeIntervalSince1970
        academic.status = 1
        return academic.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Academic> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Academic.self, req.parameters.next(Academic.self), req.content.decode(Academic.self)) { academic, newAcademic in
            academic.title = newAcademic.title
            academic.content = newAcademic.content
            academic.time = newAcademic.time
            academic.type = newAcademic.type
            academic.updatedAt = Date().timeIntervalSince1970
            return academic.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Academic.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Academic]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Academic.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Academic]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Academic.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

