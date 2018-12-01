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
    
    var readCount: Int?
    var commentCount: Int?
    var likeCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, questionID: Question.ID, content: String, readCount: Int? = 0, commentCount: Int? = 0, likeCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.questionID = questionID
        self.content = content
        self.readCount = readCount
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.status = status
    }
}

// 数据库迁移：更新字段的字段
struct UpdateAnswerField: PostgreSQLMigration {
    // 删除
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.update(Answer.self, on: conn) { builder in
            builder.deleteField(for: \.readCount)
        }
    }
    
    // 添加
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(Answer.self, on: conn) { builder in
            builder.field(for: \.readCount)
        }
    }
}

extension Answer: Mappable {
    func toDictionary() -> [String : Any] {
        return [
        "id": id ?? 0,
        "userID": userID,
        "questionID": questionID,
        
        "content": content,
        
        "readCount": readCount ?? 0,
        "commentCount": commentCount ?? 0,
        "likeCount": likeCount ?? 0,
        
        "status": status ?? 0,
        "remark": remark ?? 0,
        "createdAt": createdAt ?? 0,
        "updatedAt": updatedAt ?? 0
        ]
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

