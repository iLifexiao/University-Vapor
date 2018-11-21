//
//  ExaminationController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class ExaminationController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "examination")
        group.get("all", use: getAllHandler)
        group.get(Examination.parameter, use: getHandler)
        
        group.post(Examination.self, use: createHandler)
        group.patch(Examination.parameter, use: updateHandler)
        group.delete(Examination.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension ExaminationController {
    func getAllHandler(_ req: Request) throws -> Future<[Examination]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Examination.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Examination> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Examination.self)
    }
    
    func createHandler(_ req: Request, examination: Examination) throws -> Future<Examination> {
        _ = try req.requireAuthenticated(APIUser.self)
        examination.createdAt = Date().timeIntervalSince1970
        examination.status = 1
        return examination.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Examination> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Examination.self, req.parameters.next(Examination.self), req.content.decode(Examination.self)) { examination, newExamination in
            examination.name = newExamination.name
            examination.year = newExamination.year
            examination.major = newExamination.major
            examination.time = newExamination.time
            examination.site = newExamination.site
            examination.numbers = newExamination.numbers
            examination.teacher = newExamination.teacher
            examination.updatedAt = Date().timeIntervalSince1970
            return examination.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Examination.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Examination]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Examination.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.year == searchTerm)
            or.filter(\.major == searchTerm)
            or.filter(\.site == searchTerm)
            or.filter(\.teacher == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Examination]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Examination.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}

