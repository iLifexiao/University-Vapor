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
        group.get("tuples", use: getTuplesHandler)
        group.get(Answer.parameter, use: getHandler)
        
        group.post(Answer.self, use: createHandler)
        
        group.patch(Answer.parameter, "logicdel", use: logicdelHandler)
        group.patch(Answer.parameter, "unlike", use: decreaseLikeHandler)
        group.patch(Answer.parameter, "like", use: increaseLikeHandler)
        group.patch(Answer.parameter, "read", use: increaseReadHandler)
        group.patch(Answer.parameter, use: updateHandler)
        group.delete(Answer.parameter, use: deleteHandler)
        
        group.get("split", use: getPageHandler)
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension AnswerController {
    func getAllHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Answer.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的7条
        let up = (Int(page) ?? 1) * 7
        let low = up - 7
        
        return Answer.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    func getTuplesHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // 获得tuples数组
        let joinTuples = Answer.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).join(\UserInfo.userID, to: \Answer.userID).alsoDecode(UserInfo.self).all()
        
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
    
    // id
    func getHandler(_ req: Request) throws -> Future<Answer> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self)
    }
    
    func createHandler(_ req: Request, answer: Answer) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        answer.createdAt = Date().timeIntervalSince1970
        answer.status = 1
        answer.likeCount = 0
        answer.commentCount = 0
        answer.readCount = 0
        return answer.save(on: req).flatMap { _ in
            Question.find(answer.questionID, on: req).flatMap { question in
                guard question != nil else {
                    return try ResponseJSON<Empty>(status: .error, message: "资源不存在").encode(for: req)
                }
                
                var answerCount = question!.answerCount ?? 0
                answerCount += 1
                question!.answerCount = answerCount
                return question!.save(on: req).flatMap { _ in
                    return try ResponseJSON<Empty>(status: .ok, message: "发表成功").encode(for: req)
                }
            }
        }
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self).flatMap { answer in
            guard answer.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            answer.status = 0
            answer.updatedAt = Date().timeIntervalSince1970
            return answer.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // /id/like
    func increaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self).flatMap { answer in
            var likeCount = answer.likeCount ?? 0
            likeCount += 1
            answer.likeCount = likeCount
            return answer.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/unlike
    func decreaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self).flatMap { answer in
            var likeCount = answer.likeCount ?? 0
            likeCount -= 1
            answer.likeCount = likeCount
            return answer.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/read
    func increaseReadHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Answer.self).flatMap { answer in
            var readCount = answer.readCount ?? 0
            readCount += 1
            answer.readCount = readCount
            return answer.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
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
            or.filter(\.status != 0)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Answer.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
