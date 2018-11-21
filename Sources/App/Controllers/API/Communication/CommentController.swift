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
        
        group.patch(Comment.parameter, "logicdel", use: logicdelHandler)
        group.patch(Comment.parameter, "unlike", use: decreaseLikeHandler)
        group.patch(Comment.parameter, "like", use: increaseLikeHandler)
        group.patch(Comment.parameter, use: updateHandler)
        group.delete(Comment.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
        group.get("type", use: getAllTypeHandler)
    }
    
}

extension CommentController {
    func getAllHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Comment.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self)
    }
    
    func createHandler(_ req: Request, comment: Comment) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        comment.createdAt = Date().timeIntervalSince1970
        comment.status = 1
        comment.likeCount = 0
        return comment.save(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self).flatMap { comment in
            guard comment.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            comment.status = 0
            comment.updatedAt = Date().timeIntervalSince1970
            return comment.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
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
    
    // /id/like
    func increaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self).flatMap { comment in
            var likeCount = comment.likeCount ?? 0
            likeCount += 1
            comment.likeCount = likeCount
            return comment.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/unlike
    func decreaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self).flatMap { comment in
            var likeCount = comment.likeCount ?? 0
            likeCount -= 1
            comment.likeCount = likeCount
            return comment.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
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
            or.filter(\.status != 0)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Comment.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }

    // type?term=?&id=?
    func getAllTypeHandler(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let type = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        guard let commentID = req.query[Int.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        // 通过类型 和 ID 唯一确定评论
        return Comment.query(on: req).filter(\.status != 0).filter(\.type == type).filter(\.commentID == commentID).sort(\.createdAt, .descending).all()
    }
}
