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
    
    var readCount: Int?
    var commentCount: Int?
    var likeCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    init(id: Int? = nil, userID: User.ID, title: String, content: String, type: String, readCount: Int? = 0, commentCount: Int? = 0, likeCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.title = title
        self.content = content
        self.type = type
        self.readCount = readCount
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.status = status
    }
}

// 数据库迁移：更新字段的字段
struct UpdateExperienceField: PostgreSQLMigration {
    // 删除
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.update(Experience.self, on: conn) { builder in
            builder.deleteField(for: \.readCount)
        }
    }
    
    // 添加
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(Experience.self, on: conn) { builder in
            builder.field(for: \.readCount)
        }
    }
}

extension Experience: Mappable {
    func toDictionary() -> [String : Any] {
        return [
            "id": id ?? 0,
            "userID": userID,
            "title": title,
            "content": content,
            "type": type,
            "readCount": readCount ?? 0,
            "commentCount": commentCount ?? 0,
            "likeCount": likeCount ?? 0,
            "status": status ?? 1,
            "createdAt": createdAt ?? 0,
            "updatedAt": updatedAt ?? 0
            
        ]
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
