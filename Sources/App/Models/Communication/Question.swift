//
//  Question.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Question: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var title: String
    var type: String
    var from: String // 来源
    
    var answerCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, title: String, type: String, from: String, answerCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.title = title
        self.type = type
        self.from = from
        self.answerCount = answerCount
        self.status = status
    }
}

extension Question {
    var user: Parent<Question, User> {
        return parent(\.userID)
    }
}


extension Question: PostgreSQLMigration { }
extension Question: Content { }
extension Question: Parameter { }
