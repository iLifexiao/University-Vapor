//
//  CommentController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class CommentController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "comment")
        group.get("all", use: getAllHandler)
        group.get(Comment.parameter, use: getHandler)
        
        group.post(Comment.self, use: createHandler)
        group.patch(Comment.parameter, use: updateHandler)
        group.delete(Comment.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension CommentController {
    func getAllHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Comment.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self)
    }
    
    func createHandler(_ req: Request, comment: Comment) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        comment.createdAt = Date().timeIntervalSince1970
        return comment.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Comment.self, req.parameters.next(Comment.self), req.content.decode(Comment.self)) { comment, newComment in
            comment.content = newComment.content
            comment.updatedAt = Date().timeIntervalSince1970
            return comment.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Comment.query(on: req).group(.or) { or in
            or.filter(\.content == searchTerm)
        }.all()
    }

    func sortedHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Comment.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
