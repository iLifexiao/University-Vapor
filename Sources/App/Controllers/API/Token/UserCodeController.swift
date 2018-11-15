//
//  UserCodeController.swift
//  App
//
//  Created by 肖权 on 2018/11/15.
//

import Vapor
import FluentPostgreSQL

final class UserCodeController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "usercode")
        group.get("all", use: getAllHandler)
        group.get(UserCode.parameter, use: getHandler)
        
        group.post(UserCode.self, use: createHandler)
        group.patch(UserCode.parameter, use: updateHandler)
        group.delete(UserCode.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
        
        group.get("used", use: useUserCode)
    }
}

extension UserCodeController {
    func getAllHandler(_ req: Request) throws -> Future<[UserCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UserCode.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<UserCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UserCode.self)
    }
    
    func createHandler(_ req: Request, userCode: UserCode) throws -> Future<UserCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        let fetchedCode = UserCode.query(on: req).filter(\.code == userCode.code).first()
        return fetchedCode.flatMap { existCode in
            guard existCode == nil else {
                throw Abort(HTTPStatus.notFound, reason: "修改码已存在")
            }
            userCode.createdAt = Date().timeIntervalSince1970
            userCode.status = 1
            return userCode.save(on: req)
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<UserCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: UserCode.self, req.parameters.next(UserCode.self), req.content.decode(UserCode.self)) { userCode, newUserCode in
            userCode.code = newUserCode.code
            userCode.updatedAt = Date().timeIntervalSince1970
            return userCode.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UserCode.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[UserCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return UserCode.query(on: req).group(.or) { or in
            or.filter(\.code == searchTerm)
            }.all()
    }
    
    // used?code=
    func useUserCode(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let code = req.query[String.self, at: "code"] else {
            throw Abort(.badRequest)
        }
        let userCode = UserCode.query(on: req).filter(\.code == code).first()
        return userCode.flatMap { existCode in
            // 注册码错误
            guard existCode != nil else {
                return try ResponseJSON<Empty>(status: .userCodeInvalid).encode(for: req)
            }
            return try ResponseJSON<Empty>(status: .ok, message: "修改码有效").encode(for: req)
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[UserCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UserCode.query(on: req).sort(\.createdAt, .ascending).all()
    }
}


