//
//  User.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class User: PostgreSQLModel {
    var id: Int?
    var account: String // 电话，用于注册
    var password: String // 加密的密码
    
    var nickname: String
    var status: Int // 状态[0, 1] = [禁登、正常]
    var createdAt: TimeInterval? // 注册时间
    
    init(id: Int? = nil, account: String, password: String, nickname: String, status: Int = 1) {
        self.id = id
        self.account = account
        self.password = password
        self.nickname = nickname
        self.status = status        
    }
}

extension User: PostgreSQLMigration { }
extension User: Content { }
extension User: Parameter { }
