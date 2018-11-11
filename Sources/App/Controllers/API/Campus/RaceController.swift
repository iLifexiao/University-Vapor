//
//  RaceController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class RaceController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "race")
        group.get("all", use: getAllHandler)
        group.get(Race.parameter, use: getHandler)
        
        group.post(Race.self, use: createHandler)
        group.patch(Race.parameter, use: updateHandler)
        group.delete(Race.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }    
}

extension RaceController {
    func getAllHandler(_ req: Request) throws -> Future<[Race]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Race.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Race> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Race.self)
    }
    
    func createHandler(_ req: Request, race: Race) throws -> Future<Race> {
        _ = try req.requireAuthenticated(APIUser.self)
        race.createdAt = Date().timeIntervalSince1970
        race.status = 1
        return race.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Race> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Race.self, req.parameters.next(Race.self), req.content.decode(Race.self)) { race, newRace in
            race.imageURL = newRace.imageURL
            race.name = newRace.name
            race.content = newRace.content
            race.time = newRace.time
            race.type = newRace.type
            race.updatedAt = Date().timeIntervalSince1970
            return race.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Race.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Race]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Race.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)            
            or.filter(\.type == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Race]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Race.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

