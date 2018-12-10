//
//  UserCode.swift
//  App
//
//  Created by 肖权 on 2018/11/15.
//

import Vapor
import FluentPostgreSQL

// 修改码-用于用户忘记密码使用
final class UserCode: PostgreSQLModel {
    var id: Int?
    var userID: User.ID // 外键
    var code: String // 5位(数字+英文)
    
    var status: Int?
    var createdAt: TimeInterval?
    var updatedAt: TimeInterval?
    
    init(id: Int? = nil, userID: Int, code: String) {
        self.id = id
        self.userID = userID
        self.code = code
    }
}

extension UserCode {
    var user: Parent<UserCode, User> {
        return parent(\.userID)
    }
}

extension UserCode: PostgreSQLMigration { }
extension UserCode: Content { }
extension UserCode: Parameter { }
