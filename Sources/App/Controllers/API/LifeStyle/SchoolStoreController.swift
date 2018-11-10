//
//  SchoolStoreController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class SchoolStoreController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "schoolstore")
        group.get("all", use: getAllHandler)
        group.get(SchoolStore.parameter, use: getHandler)
        
        group.post(SchoolStore.self, use: createHandler)
        group.patch(SchoolStore.parameter, use: updateHandler)
        group.delete(SchoolStore.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension SchoolStoreController {
    func getAllHandler(_ req: Request) throws -> Future<[SchoolStore]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return SchoolStore.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<SchoolStore> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(SchoolStore.self)
    }
    
    func createHandler(_ req: Request, schoolStore: SchoolStore) throws -> Future<SchoolStore> {
        _ = try req.requireAuthenticated(APIUser.self)
        schoolStore.createdAt = Date().timeIntervalSince1970
        return schoolStore.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<SchoolStore> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: SchoolStore.self, req.parameters.next(SchoolStore.self), req.content.decode(SchoolStore.self)) { schoolStore, newSchoolStore in
            schoolStore.name = newSchoolStore.name
            schoolStore.imageURL = newSchoolStore.imageURL
            schoolStore.introduce = newSchoolStore.introduce
            schoolStore.content = newSchoolStore.content
            schoolStore.type = newSchoolStore.type
            schoolStore.site = newSchoolStore.site
            schoolStore.time = newSchoolStore.time
            schoolStore.phone = newSchoolStore.phone
            schoolStore.updatedAt = Date().timeIntervalSince1970
            return schoolStore.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(SchoolStore.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[SchoolStore]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return SchoolStore.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.introduce == searchTerm)
            or.filter(\.type == searchTerm)
            or.filter(\.site == searchTerm)
            or.filter(\.phone == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[SchoolStore]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return SchoolStore.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
