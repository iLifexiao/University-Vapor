//
//  NotificationController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class NotificationController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "notification")
        group.get("all", use: getAllHandler)
        group.get(Notification.parameter, use: getHandler)
        
        group.post(Notification.self, use: createHandler)
        group.patch(Notification.parameter, use: updateHandler)
        group.delete(Notification.parameter, use: deleteHandler)
        
        group.get("sort", use: sortedHandler)
    }
    
}

extension NotificationController {
    func getAllHandler(_ req: Request) throws -> Future<[Notification]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Notification.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Notification> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Notification.self)
    }
    
    func createHandler(_ req: Request, notification: Notification) throws -> Future<Notification> {
        _ = try req.requireAuthenticated(APIUser.self)
        notification.createdAt = Date().timeIntervalSince1970
        notification.status = 1
        return notification.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Notification> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Notification.self, req.parameters.next(Notification.self), req.content.decode(Notification.self)) { notification, newNotification in
            notification.title = newNotification.title
            notification.content = newNotification.content
            notification.type = newNotification.type
            notification.updatedAt = Date().timeIntervalSince1970
            return notification.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Notification.self).delete(on: req).transform(to: .ok)
    }
        
    func sortedHandler(_ req: Request) throws -> Future<[Notification]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Notification.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
