//
//  Answer.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Answer: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    var questionID: Question.ID
    
    var content: String
    
    var commentCount: Int?
    var likeCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, questionID: Question.ID, content: String, commentCount: Int? = 0, likeCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.questionID = questionID
        self.content = content
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.status = status
    }
}

extension Answer {
    var user: Parent<Answer, User> {
        return parent(\.userID)
    }
    
    var question: Parent<Answer, Question> {
        return parent(\.questionID)
    }
}

extension Answer: PostgreSQLMigration { }
extension Answer: Content { }
extension Answer: Parameter { }

