//
//  HolidayController.swift
//  App
//
//  Created by 肖权 on 2018/11/25.
//

import Vapor
import FluentPostgreSQL

final class HolidayController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "holiday")
        group.get("all", use: getAllHandler)
        group.get(Holiday.parameter, use: getHandler)
        
        group.post(Holiday.self, use: createHandler)
        group.patch(Holiday.parameter, use: updateHandler)
        group.delete(Holiday.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension HolidayController {
    func getAllHandler(_ req: Request) throws -> Future<[Holiday]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Holiday.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Holiday> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Holiday.self)
    }
    
    func createHandler(_ req: Request, holiday: Holiday) throws -> Future<Holiday> {
        _ = try req.requireAuthenticated(APIUser.self)
        holiday.createdAt = Date().timeIntervalSince1970        
        return holiday.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Holiday> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Holiday.self, req.parameters.next(Holiday.self), req.content.decode(Holiday.self)) { holiday, newHoliday in
            holiday.name = newHoliday.name
            holiday.time = newHoliday.time
            holiday.updatedAt = Date().timeIntervalSince1970
            return holiday.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Holiday.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Holiday]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Holiday.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.time == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Holiday]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Holiday.query(on: req).filter(\.status != 0).sort(\.createdAt, .ascending).all()
    }
}

