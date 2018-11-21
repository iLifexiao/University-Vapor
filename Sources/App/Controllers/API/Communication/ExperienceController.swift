//
//  ExperienceController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ExperienceController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "experience")
        group.get("all", use: getAllHandler)
        group.get(Experience.parameter, use: getHandler)
        
        group.post(Experience.self, use: createHandler)
        
        group.patch(Experience.parameter, "logicdel", use: logicdelHandler)
        group.patch(Experience.parameter, use: updateHandler)
        group.delete(Experience.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension ExperienceController {
    func getAllHandler(_ req: Request) throws -> Future<[Experience]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Experience.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Experience> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Experience.self)
    }
    
    func createHandler(_ req: Request, experience: Experience) throws -> Future<Experience> {
        _ = try req.requireAuthenticated(APIUser.self)
        experience.createdAt = Date().timeIntervalSince1970
        experience.status = 1
        experience.likeCount = 0
        experience.commentCount = 0
        return experience.save(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Experience.self).flatMap { experience in
            guard experience.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            experience.status = 0
            experience.updatedAt = Date().timeIntervalSince1970
            return experience.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Experience> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Experience.self, req.parameters.next(Experience.self), req.content.decode(Experience.self)) { experience, newExperience in
            experience.title = newExperience.title
            experience.content = newExperience.content
            experience.type = newExperience.type
            experience.updatedAt = Date().timeIntervalSince1970
            return experience.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Experience.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Experience]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Experience.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)
            or.filter(\.type == searchTerm)
            or.filter(\.status != 0)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Experience]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Experience.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
