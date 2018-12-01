//
//  EssayController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class EssayController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "essay")
        group.get("all", use: getAllHandler)
        group.get("tuples", use: getTuplesHandler)
        group.get(Essay.parameter, use: getHandler)
        
        group.post(Essay.self, use: createHandler)
        // 获取数组里的信息
        group.post(Essay.IDList.self, at: "list", use: getListEssayHandler)
        
        group.patch(Essay.parameter, "logicdel", use: logicdelHandler)
        group.patch(Essay.parameter, use: updateHandler)
        group.patch(Essay.parameter, "unlike", use: decreaseLikeHandler)
        group.patch(Essay.parameter, "like", use: increaseLikeHandler)
        group.patch(Essay.parameter, "read", use: increaseReadHandler)
        group.delete(Essay.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension EssayController {
    func getAllHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Essay.query(on: req).filter(\.status != 0).all()
    }
    
    func getTuplesHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // 获得tuples数组
        let joinTuples = Essay.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).join(\UserInfo.userID, to: \Essay.userID).alsoDecode(UserInfo.self).all()
        
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
    func getHandler(_ req: Request) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self)
    }
    
    func createHandler(_ req: Request, essay: Essay) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        essay.createdAt = Date().timeIntervalSince1970
        essay.status = 1
        essay.likeCount = 0
        essay.commentCount = 0
        essay.readCount = 0
        return essay.save(on: req)
    }
    
    func getListEssayHandler(_ req: Request, idList: Essay.IDList) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        var essays: [Future<Essay>] = []
        for id in idList.ids {
            essays.append(Essay.find(id, on: req).unwrap(or: Abort(HTTPStatus.notFound)))
        }
        return essays.flatten(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).flatMap { essay in
            guard essay.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            essay.status = 0
            essay.updatedAt = Date().timeIntervalSince1970
            return essay.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Essay> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Essay.self, req.parameters.next(Essay.self), req.content.decode(Essay.self)) { essay, newEssay in
            essay.title = newEssay.title
            essay.content = newEssay.content
            essay.type = newEssay.type
            essay.updatedAt = Date().timeIntervalSince1970
            return essay.save(on: req)
        }
    }
    
    // /id/like
    func increaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).flatMap { essay in
            var likeCount = essay.likeCount ?? 0
            likeCount += 1
            essay.likeCount = likeCount
            return essay.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/unlike
    func decreaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).flatMap { essay in
            var likeCount = essay.likeCount ?? 0
            likeCount -= 1
            essay.likeCount = likeCount
            return essay.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/read
    func increaseReadHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).flatMap { essay in
            var readCount = essay.readCount ?? 0
            readCount += 1
            essay.readCount = readCount
            return essay.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Essay.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Essay.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
            or.filter(\.status != 0)
        }.all()
    }
    
    // 修改文章信息的方式（倒序、排除禁止的文章）
    func sortedHandler(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Essay.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
