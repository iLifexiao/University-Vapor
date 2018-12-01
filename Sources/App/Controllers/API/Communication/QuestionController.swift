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
        
        group.get(Question.parameter, "answer", use: questionAnswersHandler)
        group.patch(Question.parameter, "logicdel", use: logicdelHandler)
        group.patch(Question.parameter, use: updateHandler)
        group.delete(Question.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get(Question.parameter, "answer", "split", use: getAnswerPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension QuestionController {
    func getAllHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Question.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的5条
        let up = (Int(page) ?? 1) * 5
        let low = up - 5
        
        return Question.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // /id/answer/split?page=1
    func getAnswerPageHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        return try req.parameters.next(Question.self).flatMap { question in
            // 查询失败，则返回最新的7条
            let up = (Int(page) ?? 1) * 7
            let low = up - 7
        
            let joinTuples = try question.answers.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).join(\UserInfo.userID, to: \Answer.userID).alsoDecode(UserInfo.self).all()
        
            // 将数组转化为想要的字典数据
            return joinTuples.map { tuples in
                let data = tuples.map { tuple -> [String : Any] in
                    var msgDict = tuple.0.toDictionary()
                    let userInfoDict = tuple.1.toDictionary()
                    msgDict["userInfo"] = userInfoDict
                    return msgDict
                }
                // 创建反应
                return try createGetResponse(req, data: data)
            }
        }
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
    
    // 获得问题的回答，/id/answer
    func questionAnswersHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Question.self).flatMap { question in
            let joinTuples = try question.answers.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).join(\UserInfo.userID, to: \Answer.userID).alsoDecode(UserInfo.self).all()
            
            // 将数组转化为想要的字典数据
            return joinTuples.map { tuples in
                let data = tuples.map { tuple -> [String : Any] in
                    var msgDict = tuple.0.toDictionary()
                    let userInfoDict = tuple.1.toDictionary()
                    msgDict["userInfo"] = userInfoDict
                    return msgDict
                }
                // 创建反应
                return try createGetResponse(req, data: data)
            }
        }
    }
    
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Question.self).flatMap { question in
            guard question.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            question.status = 0
            question.updatedAt = Date().timeIntervalSince1970
            return question.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
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
            or.filter(\.status != 0)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Question.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
