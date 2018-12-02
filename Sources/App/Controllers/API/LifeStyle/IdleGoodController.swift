//
//  IdleGoodController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class IdleGoodController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "idlegood")
        group.get("all", use: getAllHandler)
        group.get(IdleGood.parameter, use: getHandler)
        
        group.post(IdleGood.self, use: createHandler)
        group.patch(IdleGood.parameter, use: updateHandler)
        group.patch(IdleGood.parameter, "logicdel", use: logicdelHandler)
        group.delete(IdleGood.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension IdleGoodController {
    func getAllHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return IdleGood.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的 6 条
        let up = (Int(page) ?? 1) * 6
        let low = up - 6
        
        let joinTuples = IdleGood.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).join(\UserInfo.userID, to: \IdleGood.userID).alsoDecode(UserInfo.self).all()
        
        return joinTuples.map { tuples in
            let data = tuples.map { tuple -> [String : Any] in
                var msgDict = tuple.0.toDictionary()
                let userInfoDict = tuple.1.toDictionary()
                msgDict["userInfo"] = userInfoDict
                return msgDict
            }
            return try createGetResponse(req, data: data)
        }
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(IdleGood.self)
    }
    
    func createHandler(_ req: Request, idleGood: IdleGood) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        idleGood.createdAt = Date().timeIntervalSince1970
        idleGood.status = 1
        return idleGood.save(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(IdleGood.self).flatMap { idleGood in
            guard idleGood.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            idleGood.status = 0
            idleGood.updatedAt = Date().timeIntervalSince1970
            return idleGood.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<IdleGood> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: IdleGood.self, req.parameters.next(IdleGood.self), req.content.decode(IdleGood.self)) { idleGood, newIdleGood in
            idleGood.imageURLs = newIdleGood.imageURLs
            idleGood.title = newIdleGood.title
            idleGood.content = newIdleGood.content
            idleGood.originalPrice = newIdleGood.originalPrice
            idleGood.price = newIdleGood.price
            idleGood.type = newIdleGood.type
            idleGood.updatedAt = Date().timeIntervalSince1970
            return idleGood.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(IdleGood.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return IdleGood.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
            or.filter(\.status != 0)
        }.all()
    }
    
    
    func sortedHandler(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return IdleGood.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
