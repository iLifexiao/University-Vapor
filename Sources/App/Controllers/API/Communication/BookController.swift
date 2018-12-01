//
//  BookController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class BookController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "book")
        group.get("all", use: getAllHandler)
        group.get(Book.parameter, use: getHandler)
        
        group.post(Book.self, use: createHandler)
        
        group.patch(Book.parameter, "logicdel", use: logicdelHandler)
        group.patch(Book.parameter, "unlike", use: decreaseLikeHandler)
        group.patch(Book.parameter, "like", use: increaseLikeHandler)
        group.patch(Book.parameter, "read", use: increaseReadHandler)
        group.patch(Book.parameter, use: updateHandler)
        group.delete(Book.parameter, use: deleteHandler)
        
        group.get("split", use: getPageHandler)
        group.get("search", use: searchHandler)
        group.get("first", use: getFirstHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension BookController {
    func getAllHandler(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Book.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的5条
        let up = (Int(page) ?? 1) * 5
        let low = up - 5
        
        return Book.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self)
    }
    
    func createHandler(_ req: Request, book: Book) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        book.createdAt = Date().timeIntervalSince1970
        book.status = 1
        book.likeCount = 0
        book.readedCount = 0
        return book.save(on: req)
    }
    
    // 逻辑删除（status = 0）/id/logicdel
    func logicdelHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self).flatMap { book in
            guard book.status != 0 else {
                return try ResponseJSON<Empty>(status: .ok, message: "已经删除").encode(for: req)
            }
            book.status = 0
            book.updatedAt = Date().timeIntervalSince1970
            return book.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // /id/like
    func increaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self).flatMap { book in
            var likeCount = book.likeCount ?? 0
            likeCount += 1
            book.likeCount = likeCount
            return book.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/unlike
    func decreaseLikeHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self).flatMap { book in
            var likeCount = book.likeCount ?? 0
            likeCount -= 1
            book.likeCount = likeCount
            return book.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // /id/read
    func increaseReadHandler(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self).flatMap { book in
            var readCount = book.readedCount ?? 0
            readCount += 1
            book.readedCount = readCount
            return book.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok).encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Book.self, req.parameters.next(Book.self), req.content.decode(Book.self)) { book, newBook in
            book.name = newBook.name
            book.imageURL = newBook.imageURL
            book.introduce = newBook.introduce
            book.type = newBook.type
            book.author = newBook.author
            book.bookPages = newBook.bookPages
            book.updatedAt = Date().timeIntervalSince1970
            return book.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Book.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.type == searchTerm)
            or.filter(\.author == searchTerm)
            or.filter(\.status != 0)
            }.all()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Book.query(on: req).first().map(to: Book.self) { userInfo in
            guard let userInfo = userInfo else {
                throw Abort(.notFound)
            }
            return userInfo
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Book.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}
