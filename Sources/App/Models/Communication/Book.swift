//
//  Book.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Book: PostgreSQLModel {
    var id: Int?
    var userID: User.ID // 也可分为系统推荐
    
    var name: String
    var imageURL: String
    var introduce: String
    var type: String
    var author: String
    var bookPages: Int
    
    var readedCount: Int?
    var likeCount: Int?
    var commentCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, name: String, imageURL: String, introduce: String, type: String, author: String, bookPages: Int, readedCount: Int? = 0, likeCount: Int? = 0, commentCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.name = name
        self.imageURL = imageURL
        self.introduce = introduce
        self.type = type
        self.author = author
        self.bookPages = bookPages
        self.readedCount = readedCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.status = status
    }
}

// 数据库迁移：更新字段的字段
struct UpdateBookField: PostgreSQLMigration {
    // 删除
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.update(Book.self, on: conn) { builder in
            builder.deleteField(for: \.commentCount)
        }
    }
    
    // 添加
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(Book.self, on: conn) { builder in
            builder.field(for: \.commentCount)
        }
    }
}

extension Book {
    var user: Parent<Book, User> {
        return parent(\.userID)
    }
}

extension Book: PostgreSQLMigration { }
extension Book: Content { }
extension Book: Parameter { }
