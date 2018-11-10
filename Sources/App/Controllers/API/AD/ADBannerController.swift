//
//  ADBannerController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ADBannerController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "adbanner")
        group.get("all", use: getAllHandler)
        group.get(ADBanner.parameter, use: getHandler)
        
        group.post(ADBanner.self, use: createHandler)
        group.patch(ADBanner.parameter, use: updateHandler)
        group.delete(ADBanner.parameter, use: deleteHandler)
        
    }
    
}

extension ADBannerController {
    func getAllHandler(_ req: Request) throws -> Future<[ADBanner]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return ADBanner.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<ADBanner> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(ADBanner.self)
    }
    
    func createHandler(_ req: Request, adBanner: ADBanner) throws -> Future<ADBanner> {
        _ = try req.requireAuthenticated(APIUser.self)
        adBanner.createdAt = Date().timeIntervalSince1970
        return adBanner.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<ADBanner> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: ADBanner.self, req.parameters.next(ADBanner.self), req.content.decode(ADBanner.self)) { adBanner, newADBanner in
            adBanner.imageURL = newADBanner.imageURL
            adBanner.title = newADBanner.title
            adBanner.link = newADBanner.link
            adBanner.type = newADBanner.type
            adBanner.updatedAt = Date().timeIntervalSince1970
            return adBanner.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(ADBanner.self).delete(on: req).transform(to: .ok)
    }
}
