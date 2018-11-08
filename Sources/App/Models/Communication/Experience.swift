//
//  Experience.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Experience: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var title: String
    var content: String
    var type: String
    var commentCount: Int
    var likeCount: Int
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    
    init(id: Int? = nil, userID: User.ID, title: String, content: String, type: String, commentCount: Int = 0, likeCount: Int = 0, status: Int = 1) {
        self.id = id
        self.userID = userID
        self.title = title
        self.content = content
        self.type = type
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.status = status
    }
}

extension Experience {
    var user: Parent<Experience, User> {
        return parent(\.userID)
    }
}

extension Experience: PostgreSQLMigration { }
extension Experience: Content { }
extension Experience: Parameter { }
