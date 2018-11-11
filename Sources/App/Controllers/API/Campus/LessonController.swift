//
//  LessonController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class LessonController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "lesson")
        group.get("all", use: getAllHandler)
        group.get(Lesson.parameter, use: getHandler)
        
        group.post(Lesson.self, use: createHandler)
        group.patch(Lesson.parameter, use: updateHandler)
        group.delete(Lesson.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension LessonController {
    func getAllHandler(_ req: Request) throws -> Future<[Lesson]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Lesson.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Lesson> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Lesson.self)
    }
    
    func createHandler(_ req: Request, lesson: Lesson) throws -> Future<Lesson> {
        _ = try req.requireAuthenticated(APIUser.self)
        lesson.createdAt = Date().timeIntervalSince1970
        lesson.status = 1
        return lesson.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Lesson> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Lesson.self, req.parameters.next(Lesson.self), req.content.decode(Lesson.self)) { lesson, newLesson in
            lesson.timeInWeek = newLesson.timeInWeek
            lesson.timeInDay = newLesson.timeInDay
            lesson.timeInTerm = newLesson.timeInTerm
            lesson.name = newLesson.name
            lesson.teacher = newLesson.teacher
            lesson.site = newLesson.site
            lesson.updatedAt = Date().timeIntervalSince1970
            return lesson.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Lesson.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Lesson]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Lesson.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.teacher == searchTerm)
            or.filter(\.site == searchTerm)
            or.filter(\.timeInWeek == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Lesson]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Lesson.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

