//
//  ResourceController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ResourceController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "resource")
        group.get("all", use: getAllHandler)
        group.get(Resource.parameter, use: getHandler)
        
        group.post(Resource.self, use: createHandler)
        
        group.patch(Resource.parameter, "logicdel", use: logicdelHandler)
        group.patch(Resource.parameter, use: updateHandler)
        group.delete(Resource.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension ResourceController {
    func getAllHandler(_ req: Request) throws -> Future<[Resource]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Resource.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Resource> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Resource.self)
    }
    
    func createHandler(_ req: Request, resource: Resource) throws -> Future<Resource> {
        _ = try req.requireAuthenticated(APIUser.self)
        resource.createdAt = Date().timeIntervalSince1970
        resource.status = 1
        resource.commentCount = 0
        resource.likeCount = 0
        return resource.save(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Resource.self).flatMap { resource in
            guard resource.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            resource.status = 0
            resource.updatedAt = Date().timeIntervalSince1970
            return resource.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Resource> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Resource.self, req.parameters.next(Resource.self), req.content.decode(Resource.self)) { resource, newResource in
            resource.imageURL = newResource.imageURL
            resource.name = newResource.name
            resource.introduce = newResource.introduce
            resource.type = newResource.type
            
            return resource.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Resource.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Resource]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Resource.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.type == searchTerm)
            or.filter(\.status != 0)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Resource]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Resource.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
