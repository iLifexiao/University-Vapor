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
        group.patch(Book.parameter, use: updateHandler)
        group.delete(Book.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("first", use: getFirstHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension BookController {
    func getAllHandler(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Book.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Book.self)
    }
    
    func createHandler(_ req: Request, book: Book) throws -> Future<Book> {
        _ = try req.requireAuthenticated(APIUser.self)
        book.createdAt = Date().timeIntervalSince1970
        return book.save(on: req)
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
        return Book.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
