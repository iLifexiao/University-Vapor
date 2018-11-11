//
//  Focus.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Focus: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    var focusUserID: User.ID
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 关注时间    
    
    init(id: Int? = nil, userID: User.ID, focusUserID: User.ID, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.focusUserID = focusUserID
        self.status = status
    }
}

extension Focus {
    var user: Parent<Focus, User> {
        return parent(\.userID)
    }
    
    var focusUser: Parent<Focus, User> {
        return parent(\.focusUserID)
    }
}

extension Focus: PostgreSQLMigration { }
extension Focus: Content { }
extension Focus: Parameter { }
