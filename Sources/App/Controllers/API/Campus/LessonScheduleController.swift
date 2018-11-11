//
//  LessonScheduleController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class LessonScheduleController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "lessonschedule")
        group.get("all", use: getAllHandler)
        group.get(LessonSchedule.parameter, use: getHandler)
        
        group.post(LessonSchedule.self, use: createHandler)
        group.patch(LessonSchedule.parameter, use: updateHandler)
        group.delete(LessonSchedule.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }    
}

extension LessonScheduleController {
    func getAllHandler(_ req: Request) throws -> Future<[LessonSchedule]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LessonSchedule.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<LessonSchedule> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LessonSchedule.self)
    }
    
    func createHandler(_ req: Request, lessonSchedule: LessonSchedule) throws -> Future<LessonSchedule> {
        _ = try req.requireAuthenticated(APIUser.self)
        lessonSchedule.createdAt = Date().timeIntervalSince1970
        lessonSchedule.status = 1
        return lessonSchedule.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<LessonSchedule> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: LessonSchedule.self, req.parameters.next(LessonSchedule.self), req.content.decode(LessonSchedule.self)) { lessonSchedule, newLessonSchedule in
            lessonSchedule.year = newLessonSchedule.year
            lessonSchedule.term = newLessonSchedule.term
            lessonSchedule.updatedAt = Date().timeIntervalSince1970
            return lessonSchedule.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LessonSchedule.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[LessonSchedule]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return LessonSchedule.query(on: req).group(.or) { or in
            or.filter(\.year == searchTerm)
            or.filter(\.term == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[LessonSchedule]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LessonSchedule.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

