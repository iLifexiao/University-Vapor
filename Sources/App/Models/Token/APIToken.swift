//
//  APIToken.swift
//  App
//
//  Created by 肖权 on 2018/9/14.
//

import FluentPostgreSQL
import Authentication

// 继承你服务器使用的数据库模型
final class APIToken: PostgreSQLModel {
    var id: Int?
    var token: String
    var userId: APIUser.ID
    
    init(token: String, userId: APIUser.ID) {
        self.token = token
        self.userId = userId
    }
}

// 通过扩展来实现功能分离，可以看出 面向协议编程 的好处
extension APIToken {
    // 表示 APIToken 的父母是 APIUser
    var user: Parent<APIToken, APIUser> {
        return parent(\.userId)
    }
}

// 实现BearerAuthenticatable协议
extension APIToken: BearerAuthenticatable {
    // 让其知道模型中哪个属性才是token
    static var tokenKey: WritableKeyPath<APIToken, String> {
        return \.token
    }
}

// 实现Token协议
extension APIToken: Token {
    typealias UserType = APIUser
    typealias UserIDType = APIUser.ID
    
    static var userIDKey: WritableKeyPath<APIToken, APIUser.ID> {
        return \.userId
    }
}

extension APIToken: PostgreSQLMigration {}
extension APIToken: Content {}
