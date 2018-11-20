//
//  MessageController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class MessageController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "message")
        group.get("all", use: getAllHandler)
        group.get(Message.parameter, use: getHandler)
        
        group.post(Message.self, use: createHandler)
        group.post(Message.SendAccount.self, at: "account", use: sendMsgByAccount)
        group.delete(Message.parameter, use: deleteHandler)
        
        group.get("sort", use: sortedHandler)
    }
    
}

extension MessageController {
    func getAllHandler(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Message> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Message.self)
    }
    
    func createHandler(_ req: Request, message: Message) throws -> Future<Message> {
        _ = try req.requireAuthenticated(APIUser.self)
        message.createdAt = Date().timeIntervalSince1970
        message.status = 1
        return message.save(on: req)
    }
    
    // message/account
    func sendMsgByAccount(_ req: Request, message: Message.SendAccount) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        
        return User.query(on: req).filter(\.account == message.account).first().flatMap { fetchUser in
            guard let existUser = fetchUser else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            // 防止用户给自己发送私信
            guard message.userID != existUser.id! else {
                return try ResponseJSON<Empty>(status: .error, message: "不能给自己发送私信~").encode(for: req)
            }
            
            // 表的设计，保证单方用户删除信息不会造成干扰
            let msg1 = Message(userID: message.userID, friendID: existUser.id!, fromUserID: message.userID, toUserID: existUser.id!, content: message.content, type: message.type, status: 1)
            msg1.createdAt = Date().timeIntervalSince1970
            let msg2 = Message(userID: existUser.id!, friendID: message.userID, fromUserID: message.userID, toUserID: existUser.id!, content: message.content, type: message.type, status: 1)
            msg2.createdAt = msg1.createdAt
            
            // 更新多伦保存数据库的方式，队列
            // 保证所有的操作完成后才会执行写入数据库操作
            // 链式的写法有很多种，下面是新的方式
            return req.transaction(on: .psql) { conn in
                return msg1.save(on: conn).flatMap { _ in
                    return msg2.save(on: conn)
                    }.flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "私信发送成功").encode(for: req)
                }
            }           
        }
    }
    

    
    // id
    func deleteHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Message.self).delete(on: req).flatMap { msg in
            return try ResponseJSON<Empty>(status: .ok, message: "私信删除成功").encode(for: req)
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

