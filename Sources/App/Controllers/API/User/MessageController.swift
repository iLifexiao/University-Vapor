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
        group.get("tuples", use: getTuplesHandler)
        group.get(Message.parameter, use: getHandler)
        
        group.post(Message.self, use: createHandler)
        group.post(Message.self, at: "two", use: createHandlerTwo)
        group.post(Message.PeopleIM.self, at: "delall", use: delAllHandler)
        group.post(Message.PeopleIM.self, at: "readall", use: readAllHandler)
        group.post(Message.PeopleIM.self, at: "showim", use: getPeopleIMHandler)
        group.post(Message.SendAccount.self, at: "account", use: sendMsgByAccount)
        group.delete(Message.parameter, use: deleteHandler)
        group.patch(Message.parameter, "logicdel", use: logicdelHandler)
        
        group.get("sort", use: sortedHandler)
    }
    
}

extension MessageController {
    // 表的链接，返回元组
    func getAllHandler(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).filter(\.status != 0).filter(\.status != 3).all()
    }
    
    func getTuplesHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // 获得tuples数组
        let joinTuples = Message.query(on: req).join(\UserInfo.userID, to: \Message.friendID).alsoDecode(UserInfo.self).all()
        
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
    
    // 点击用户发送私信 /message/two
    func createHandlerTwo(_ req: Request, message: Message) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard message.fromUserID != message.toUserID else {
            return try ResponseJSON<Empty>(status: .ok, message: "不能给自己发送私信哦~").encode(for: req)
        }
        
        message.createdAt = Date().timeIntervalSince1970
        message.status = 2
        
        // 第二条信息
        let msg2 = Message(userID: message.friendID, friendID: message.userID, fromUserID: message.fromUserID, toUserID: message.toUserID, content: message.content)
        msg2.createdAt = message.createdAt
        msg2.status = 1
        
        return req.transaction(on: .psql) { conn in
            message.save(on: conn).flatMap { _ in
                return msg2.save(on: conn)
                }.flatMap { _ in
                    return try ResponseJSON<Empty>(status: .ok, message: "私信发送成功").encode(for: req)
            }
        }
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
            let msg1 = Message(userID: message.userID, friendID: existUser.id!, fromUserID: message.userID, toUserID: existUser.id!, content: message.content, type: message.type, status: 2)
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
    
    // 逻辑删除（status = 3）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Message.self).flatMap { message in
            guard message.status != 3 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            message.status = 3
            message.updatedAt = Date().timeIntervalSince1970
            return message.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    func delAllHandler(_ req: Request, info: Message.PeopleIM) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).filter(\.userID == info.userID).filter(\.friendID == info.friendID).filter(\.status != 0).filter(\.status != 3).all().flatMap { messages in
            var responses: [Future<Message>] = []
            for msg in messages {
                msg.status = 3
                msg.updatedAt = Date().timeIntervalSince1970
                responses.append(msg.save(on: req))
            }
            return responses.flatten(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "私信删除成功").encode(for: req)
            }
        }
    }

    func readAllHandler(_ req: Request, info: Message.PeopleIM) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).filter(\.userID == info.userID).filter(\.friendID == info.friendID).filter(\.status == 1).all().flatMap { messages in
            var responses: [Future<Message>] = []
            for msg in messages {
                msg.status = 2
                msg.updatedAt = Date().timeIntervalSince1970
                responses.append(msg.save(on: req))
            }
            return responses.flatten(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "标记全部已读成功").encode(for: req)
            }
        }
    }
    
    func getPeopleIMHandler(_ req: Request, info: Message.PeopleIM) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        let joinTuples = Message.query(on: req).filter(\.userID == info.userID).filter(\.friendID == info.friendID).filter(\.status != 0).filter(\.status != 3).join(\UserInfo.userID, to: \Message.friendID).alsoDecode(UserInfo.self).all()
        
        // 将数组转化为想要的字典数据
        return joinTuples.map { tuples in
            let data = tuples.map { tuple -> [String : Any] in
                let msg = tuple.0
                if msg.status == 1 {
                    msg.status = 2
                    msg.updatedAt = Date().timeIntervalSince1970
                    _ = msg.save(on: req)
                }
                var msgDict = msg.toDictionary()
                let userInfoDict = tuple.1.toDictionary()
                msgDict["userInfo"] = userInfoDict
                return msgDict
            }
            // 创建反应
            return try createGetResponse(req, data: data)
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
        return Message.query(on: req).filter(\.status != 0).filter(\.status != 3).sort(\.createdAt, .descending).all()
    }
}

