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
    var type: String // 类型「普通、系统」
    var status: Int // 状态[0, 1, 2, 3] = [禁止、 未读、已读、删除]
    var createdAt: TimeInterval? // 创建时间
    
    
    init(id: Int? = nil, userID: User.ID, friendID: User.ID, fromUserID: User.ID, toUserID: User.ID, content: String, type: String, status: Int = 1) {
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

extension Message {
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
