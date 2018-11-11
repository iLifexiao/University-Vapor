//
//  AnswerController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class AnswerController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "answer")
        group.get("all", use: getAllHandler)
        group.get(Answer.parameter, use: getHandler)
        
        group.post(Answer.self, use: createHandler)
        group.patch(Answer.parameter, use: updateHandler)
        group.delete(Answer.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension AnswerController {
    func getAllHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Answer.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Answer> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self)
    }
    
    func createHandler(_ req: Request, answer: Answer) throws -> Future<Answer> {
        _ = try req.requireAuthenticated(APIUser.self)
        answer.createdAt = Date().timeIntervalSince1970
        answer.status = 1
        answer.likeCount = 0
        answer.commentCount = 0
        return answer.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Answer> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Answer.self, req.parameters.next(Answer.self), req.content.decode(Answer.self)) { answer, newAnswer in
            answer.content = newAnswer.content
            answer.updatedAt = Date().timeIntervalSince1970
            return answer.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Answer.query(on: req).group(.or) { or in
            or.filter(\.content == searchTerm)
        }.all()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Answer> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Answer.query(on: req).first().map(to: Answer.self) { userInfo in
            guard let userInfo = userInfo else {
                throw Abort(.notFound)
            }
            return userInfo
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Answer.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
