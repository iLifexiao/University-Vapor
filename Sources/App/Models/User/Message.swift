//
//  Message.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class Message: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    var friendID: User.ID
    var fromUserID: User.ID
    var toUserID: User.ID
    
    var content: String
    var type: String? // 类型「普通、系统」
    var status: Int? // 状态[0, 1, 2] = [删除、未读、已读]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval?
    
    init(id: Int? = nil, userID: User.ID, friendID: User.ID, fromUserID: User.ID, toUserID: User.ID, content: String, type: String? = "普通", status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.friendID = friendID
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.content = content
        self.type = type
        self.status = status
    }
}

// 数据库迁移：更新字段的字段
struct UpdateMessageField: PostgreSQLMigration {
    // 删除
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.update(Message.self, on: conn) { builder in
            builder.deleteField(for: \.updatedAt)
        }
    }
    
    // 添加
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(Message.self, on: conn) { builder in
            builder.field(for: \.updatedAt)
        }
    }
}

extension Message: Mappable {
    func toDictionary() -> [String : Any] {
        return [
            "id": id ?? 0,
            "userID": userID,
            "friendID": friendID,
            "fromUserID": fromUserID,
            "toUserID": toUserID,
            "content": content,
            "type": type ?? "普通",
            "status": status ?? 1,
            "createdAt": createdAt ?? 0,
            "updatedAt": updatedAt ?? 0
        ]
    }
}

extension Message {
    // 发送信息的格式
    struct SendAccount: Content {
        var userID: Int
        var account: String
        var content: String
        var type: String
    }
    
    // 批量删除、查找于他人的聊天记录
    struct PeopleIM: Content {
        var userID: Int
        var friendID: Int
    }
    
    var user: Parent<Message, User> {
        return parent(\.userID)
    }
    
    var friend: Parent<Message, User> {
        return parent(\.friendID)
    }
    
    var fromUser: Parent<Message, User> {
        return parent(\.fromUserID)
    }
    
    var toUser: Parent<Message, User> {
        return parent(\.toUserID)
    }
}

extension Message: PostgreSQLMigration { }
extension Message: Content { }
extension Message: Parameter { }
