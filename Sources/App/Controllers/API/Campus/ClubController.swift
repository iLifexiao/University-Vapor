//
//  ClubController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ClubController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "club")
        group.get("all", use: getAllHandler)
        group.get(Club.parameter, use: getHandler)
        
        group.post(Club.self, use: createHandler)
        group.patch(Club.parameter, use: updateHandler)
        group.delete(Club.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension ClubController {
    func getAllHandler(_ req: Request) throws -> Future<[Club]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Club.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[Club]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的10条
        let up = (Int(page) ?? 1) * 10
        let low = up - 10
        
        return Club.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Club> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Club.self)
    }
    
    func createHandler(_ req: Request, club: Club) throws -> Future<Club> {
        _ = try req.requireAuthenticated(APIUser.self)
        club.createdAt = Date().timeIntervalSince1970
        club.status = 1
        return club.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Club> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Club.self, req.parameters.next(Club.self), req.content.decode(Club.self)) { club, newClub in
            club.imageURL = newClub.imageURL
            club.name = newClub.name
            club.introduce = newClub.introduce
            club.time = newClub.time
            club.numbers = newClub.numbers
            club.rank = newClub.rank
            club.type = newClub.type
            club.updatedAt = Date().timeIntervalSince1970
            return club.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Club.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Club]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Club.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.rank == searchTerm)
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Club]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Club.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}

