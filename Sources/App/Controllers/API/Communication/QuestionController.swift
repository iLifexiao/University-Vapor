//
//  QuestionController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class QuestionController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "question")
        group.get("all", use: getAllHandler)
        group.get(Question.parameter, use: getHandler)
        
        group.post(Question.self, use: createHandler)
        group.patch(Question.parameter, use: updateHandler)
        group.delete(Question.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension QuestionController {
    func getAllHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Question.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Question> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Question.self)
    }
    
    func createHandler(_ req: Request, question: Question) throws -> Future<Question> {
        _ = try req.requireAuthenticated(APIUser.self)
        question.createdAt = Date().timeIntervalSince1970
        question.status = 1
        question.answerCount = 0
        return question.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Question> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Question.self, req.parameters.next(Question.self), req.content.decode(Question.self)) { question, newQuestion in
            question.title = newQuestion.title
            question.type = newQuestion.type
            question.from = newQuestion.from
            question.updatedAt = Date().timeIntervalSince1970
            return question.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Question.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Question.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)
            or.filter(\.type == searchTerm)
            or.filter(\.from == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Question.query(on: req).sort(\.createdAt, .ascending).all()
    }
}