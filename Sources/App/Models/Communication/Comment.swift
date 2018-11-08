//
//  Comment.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Comment: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var content: String
    var likeCount: Int
    var type: String // [Resource, Essay, CampusNews, Book, Question, Answer, Experience]
    var commentID: Int
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    
    init(id: Int? = nil, userID: User.ID, content: String, likeCount: Int = 0, type: String, commentID: Int, status: Int = 1) {
        self.id = id
        self.userID = userID
        self.content = content
        self.likeCount = likeCount
        self.type = type
        self.commentID = commentID
        self.status = status
    }
}

extension Comment {
    var user: Parent<Comment, User> {
        return parent(\.userID)
    }
}

extension Comment: PostgreSQLMigration { }
extension Comment: Content { }
extension Comment: Parameter { }
