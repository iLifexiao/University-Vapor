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
        group.get("tuples", use: getTuplesHandler)
        group.get(Comment.parameter, use: getHandler)
        
        group.post(Comment.self, use: createHandler)
        
        group.patch(Comment.parameter, "logicdel", use: logicdelHandler)
        group.patch(Comment.parameter, "unlike", use: decreaseLikeHandler)
        group.patch(Comment.parameter, "like", use: increaseLikeHandler)
        group.patch(Comment.parameter, use: updateHandler)
        group.delete(Comment.parameter, use: deleteHandler)
        
        group.get("type", "split", use: getPageHandler)
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
    
    func getPageHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let type = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        guard let commentID = req.query[Int.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的10条
        let up = (Int(page) ?? 1) * 10
        let low = up - 10
        
        let joinTuples = Comment.query(on: req).filter(\.status != 0).filter(\.type == type).filter(\.commentID == commentID).range(low..<up).join(\UserInfo.userID, to: \Comment.userID).alsoDecode(UserInfo.self).all()
        
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
    
    func getTuplesHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // 获得tuples数组
        let joinTuples = Comment.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).join(\UserInfo.userID, to: \Comment.userID).alsoDecode(UserInfo.self).all()
        
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
    func getHandler(_ req: Request) throws -> Future<Comment> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Comment.self)
    }
    
    func createHandler(_ req: Request, comment: Comment) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        
        switch comment.type {
        case "Essay":
            return Essay.find(comment.commentID, on: req).flatMap { essay in
                guard let essay = essay else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = essay.commentCount ?? 0
                commentCount += 1
                essay.commentCount = commentCount
                return essay.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }
        case "CampusNews":
            return CampusNews.find(comment.commentID, on: req).flatMap { campusNews in
                guard let campusNews = campusNews else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = campusNews.commentCount ?? 0
                commentCount += 1
                campusNews.commentCount = commentCount
                return campusNews.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }
        case "Resource":
            return Resource.find(comment.commentID, on: req).flatMap { resource in
                guard let resource = resource else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = resource.commentCount ?? 0
                commentCount += 1
                resource.commentCount = commentCount
                return resource.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }
        case "Answer":
            return Answer.find(comment.commentID, on: req).flatMap { answer in
                guard let answer = answer else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = answer.commentCount ?? 0
                commentCount += 1
                answer.commentCount = commentCount
                return answer.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }
        case "Book":
            return Book.find(comment.commentID, on: req).flatMap { book in
                guard let book = book else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = book.commentCount ?? 0
                commentCount += 1
                book.commentCount = commentCount
                return book.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }
        case "Experience":
            return Experience.find(comment.commentID, on: req).flatMap { experience in
                guard let experience = experience else {
                    return try ResponseJSON<Empty>(status: .error, message: "该资源不存在，无法评论").encode(for: req)
                }
                // 评论数量 +1
                var commentCount = experience.commentCount ?? 0
                commentCount += 1
                experience.commentCount = commentCount
                return experience.save(on: req).flatMap { _ in
                    comment.createdAt = Date().timeIntervalSince1970
                    comment.status = 1
                    comment.likeCount = 0
                    return comment.save(on: req).flatMap { _ in
                        return try ResponseJSON<Empty>(status: .ok, message: "评论成功").encode(for: req)
                    }
                }
            }

        default:
            return try ResponseJSON<Empty>(status: .error, message: "该类型不存在，无法评论").encode(for: req)
        }
 
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
    func getAllTypeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let type = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        guard let commentID = req.query[Int.self, at: "id"] else {
            throw Abort(.badRequest)
        }
        // 通过类型 和 ID 唯一确定评论
        let joinTuples = Comment.query(on: req).filter(\.status != 0).filter(\.type == type).filter(\.commentID == commentID).sort(\.createdAt, .descending).join(\UserInfo.userID, to: \Comment.userID).alsoDecode(UserInfo.self).all()
        
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
}
