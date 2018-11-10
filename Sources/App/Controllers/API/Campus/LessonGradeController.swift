//
//  LessonGradeController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class LessonGradeController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "lessongrade")
        group.get("all", use: getAllHandler)
        group.get(LessonGrade.parameter, use: getHandler)
        
        group.post(LessonGrade.self, use: createHandler)
        group.patch(LessonGrade.parameter, use: updateHandler)
        group.delete(LessonGrade.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension LessonGradeController {
    func getAllHandler(_ req: Request) throws -> Future<[LessonGrade]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LessonGrade.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<LessonGrade> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LessonGrade.self)
    }
    
    func createHandler(_ req: Request, lessonGrade: LessonGrade) throws -> Future<LessonGrade> {
        _ = try req.requireAuthenticated(APIUser.self)
        lessonGrade.createdAt = Date().timeIntervalSince1970
        return lessonGrade.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<LessonGrade> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: LessonGrade.self, req.parameters.next(LessonGrade.self), req.content.decode(LessonGrade.self)) { lessonGrade, newLessonGrade in
            lessonGrade.no = newLessonGrade.no
            lessonGrade.name = newLessonGrade.name
            lessonGrade.type = newLessonGrade.type
            lessonGrade.credit = newLessonGrade.credit
            lessonGrade.gradePoint = newLessonGrade.gradePoint
            lessonGrade.grade = newLessonGrade.grade
            lessonGrade.updatedAt = Date().timeIntervalSince1970
            return lessonGrade.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(LessonGrade.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[LessonGrade]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return LessonGrade.query(on: req).group(.or) { or in
            or.filter(\.no == searchTerm)
            or.filter(\.name == searchTerm)
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[LessonGrade]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return LessonGrade.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

