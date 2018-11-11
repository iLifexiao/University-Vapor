//
//  ShootAndPrintController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ShootAndPrintController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "shootandprint")
        group.get("all", use: getAllHandler)
        group.get(ShootAndPrint.parameter, use: getHandler)
        
        group.post(ShootAndPrint.self, use: createHandler)
        group.patch(ShootAndPrint.parameter, use: updateHandler)
        group.delete(ShootAndPrint.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension ShootAndPrintController {
    func getAllHandler(_ req: Request) throws -> Future<[ShootAndPrint]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return ShootAndPrint.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<ShootAndPrint> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(ShootAndPrint.self)
    }
    
    func createHandler(_ req: Request, shootAndPrint: ShootAndPrint) throws -> Future<ShootAndPrint> {
        _ = try req.requireAuthenticated(APIUser.self)
        shootAndPrint.createdAt = Date().timeIntervalSince1970
        shootAndPrint.status = 1
        return shootAndPrint.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<ShootAndPrint> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: ShootAndPrint.self, req.parameters.next(ShootAndPrint.self), req.content.decode(ShootAndPrint.self)) { shootAndPrint, newShootAndPrint in
            
            shootAndPrint.name = newShootAndPrint.name
            shootAndPrint.imageURL = newShootAndPrint.imageURL
            shootAndPrint.introduce = newShootAndPrint.introduce
            shootAndPrint.content = newShootAndPrint.content
            shootAndPrint.time = newShootAndPrint.time
            shootAndPrint.site = newShootAndPrint.site
            shootAndPrint.phone = newShootAndPrint.phone
            shootAndPrint.wechat = newShootAndPrint.wechat
            shootAndPrint.qq = newShootAndPrint.qq
            shootAndPrint.updatedAt = Date().timeIntervalSince1970
            return shootAndPrint.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(ShootAndPrint.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[ShootAndPrint]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return ShootAndPrint.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.site == searchTerm)
            or.filter(\.introduce == searchTerm)
            or.filter(\.phone == searchTerm)
            or.filter(\.wechat == searchTerm)
            or.filter(\.qq == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[ShootAndPrint]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return ShootAndPrint.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
