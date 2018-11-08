//
//  APIUser.swift
//  App
//
//  Created by 肖权 on 2018/9/14.
//

import Vapor
import FluentPostgreSQL
import Authentication

final class APIUser: PostgreSQLModel {
    var id: Int?
    var name: String
    var email: String
    var password: String
    
    init(id: Int? = nil, name: String , email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }
}

// 实现TokenAuthenticatable协议，告诉其`token`的类型
extension APIUser: TokenAuthenticatable {
    typealias TokenType = APIToken
}

// 设计注册后可以公开的用户结构
extension APIUser {
    struct UserPublic: Content {
        let id: Int
        let name :String
        let email: String
    }
}

extension APIUser: PostgreSQLMigration {}
extension APIUser: Content {}
