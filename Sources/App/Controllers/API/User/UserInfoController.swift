//
//  UserInfoController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class UserInfoController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "userinfo")
        group.get("all", use: getAllHandler)
        group.get(UserInfo.parameter, use: getHandler)
        
        group.post(UserInfo.self, use: createHandler)
        group.patch(UserInfo.parameter, use: updateHandler)
        group.delete(UserInfo.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
}

extension UserInfoController {
    func getAllHandler(_ req: Request) throws -> Future<[UserInfo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UserInfo.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<UserInfo> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UserInfo.self)
    }
    
    func createHandler(_ req: Request, userInfo: UserInfo) throws -> Future<UserInfo> {
        _ = try req.requireAuthenticated(APIUser.self)
        userInfo.createdAt = Date().timeIntervalSince1970
        return userInfo.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<UserInfo> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: UserInfo.self, req.parameters.next(UserInfo.self), req.content.decode(UserInfo.self)) { userInfo, newUserInfo in
            userInfo.nickname = newUserInfo.nickname
            userInfo.profilephoto = newUserInfo.profilephoto
            userInfo.sex = newUserInfo.sex
            userInfo.age = newUserInfo.age
            userInfo.phone = newUserInfo.phone
            userInfo.email = newUserInfo.email
            userInfo.introduce = newUserInfo.introduce
            userInfo.updatedAt = Date().timeIntervalSince1970
            return userInfo.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UserInfo.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[UserInfo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return UserInfo.query(on: req).group(.or) { or in
            or.filter(\.nickname == searchTerm)
            or.filter(\.phone == searchTerm)
            or.filter(\.email == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[UserInfo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UserInfo.query(on: req).sort(\.nickname, .ascending).all()
    }
}

