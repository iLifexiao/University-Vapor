//
//  PropertyManagerController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class PropertyManagerController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "propertymanager")
        group.get("all", use: getAllHandler)
        group.get(PropertyManager.parameter, use: getHandler)
        
        group.post(PropertyManager.self, use: createHandler)
        group.patch(PropertyManager.parameter, use: updateHandler)
        group.delete(PropertyManager.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension PropertyManagerController {
    func getAllHandler(_ req: Request) throws -> Future<[PropertyManager]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return PropertyManager.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[PropertyManager]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的10条
        let up = (Int(page) ?? 1) * 10
        let low = up - 10
        
        return PropertyManager.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<PropertyManager> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(PropertyManager.self)
    }
    
    func createHandler(_ req: Request, propertyManager: PropertyManager) throws -> Future<PropertyManager> {
        _ = try req.requireAuthenticated(APIUser.self)
        propertyManager.createdAt = Date().timeIntervalSince1970
        propertyManager.status = 1
        return propertyManager.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<PropertyManager> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: PropertyManager.self, req.parameters.next(PropertyManager.self), req.content.decode(PropertyManager.self)) { propertyManager, newPropertyManager in
            
            propertyManager.imageURL = newPropertyManager.imageURL
            propertyManager.name = newPropertyManager.name
            propertyManager.phone = newPropertyManager.phone
            propertyManager.ability = newPropertyManager.ability
            propertyManager.updatedAt = Date().timeIntervalSince1970
            return propertyManager.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(PropertyManager.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[PropertyManager]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return PropertyManager.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.phone == searchTerm)
            or.filter(\.ability == searchTerm)
            or.filter(\.status != 0)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[PropertyManager]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return PropertyManager.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
