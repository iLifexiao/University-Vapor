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
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Message.self).delete(on: req).transform(to: .ok)
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Message.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

