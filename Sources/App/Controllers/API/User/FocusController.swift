//
//  FocusController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class FocusController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "focus")
        group.get("all", use: getAllHandler)
        group.get(Focus.parameter, use: getHandler)
        
        group.post(Focus.self, use: createHandler)
        group.post(Focus.Account.self, at: "account", use: createHandlerByAccount)
        group.delete(Focus.parameter, use: deleteHandler)
        // 删除方法不能通过delete来传送数据，改用POST，标志是使用at作为参数
        group.post(Focus.self, at: "delete", use: deleteHandlerByUserID)
        
        group.get("sort", use: sortedHandler)
    }
    
}

extension FocusController {
    func getAllHandler(_ req: Request) throws -> Future<[Focus]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Focus.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Focus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Focus.self)
    }
    
    func createHandler(_ req: Request, focus: Focus) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        focus.createdAt = Date().timeIntervalSince1970
        focus.status = 1
        
        return Focus.query(on: req).filter(\.userID == focus.userID).filter(\.focusUserID == focus.focusUserID).first().flatMap { fetchFocus in
            // 避免重复关注
            guard fetchFocus == nil else {
                return try ResponseJSON<Empty>(status: .error, message: "你已经关注该用户了").encode(for: req)
            }
            
            return focus.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "回关成功").encode(for: req)
            }
        }
    }
    // /account
    func createHandlerByAccount(_ req: Request, focusAccount: Focus.Account) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return User.query(on: req).filter(\.account == focusAccount.account).first().flatMap { user in
            guard let existUser = user else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            
            // 不能关注自己
            guard focusAccount.userID != existUser.id! else {
                return try ResponseJSON<Empty>(status: .error, message: "不能关注自己~").encode(for: req)
            }
            
            return Focus.query(on: req).filter(\.userID == focusAccount.userID).filter(\.focusUserID == existUser.id!).first().flatMap { fetchFocus in
                // 避免重复关注
                guard fetchFocus == nil else {
                    return try ResponseJSON<Empty>(status: .error, message: "你已经关注该用户了").encode(for: req)
                }
                
                let focus = Focus(userID: focusAccount.userID, focusUserID: existUser.id!)
                focus.createdAt = Date().timeIntervalSince1970
                focus.status = 1
                return focus.save(on: req).flatMap { _ in
                    return try ResponseJSON<Empty>(status: .ok, message: "关注成功").encode(for: req)
                }
            }
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Focus.self).delete(on: req).transform(to: .ok)
    }
    
    // 取消关注用户
    // /delete
    func deleteHandlerByUserID(_ req: Request, focus: Focus) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Focus.query(on: req).filter(\.userID == focus.userID).filter(\.focusUserID == focus.focusUserID).first().flatMap { focus in
            guard let existFocus = focus else {
                return try ResponseJSON<Empty>(status: .error, message: "用户不存在").encode(for: req)
            }
            return existFocus.delete(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "取消关注成功").encode(for: req)
            }
        }
    }
       
    func sortedHandler(_ req: Request) throws -> Future<[Focus]> {
        _ = try req.requireAuthenticated(APIUser.self)        
        return Focus.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

