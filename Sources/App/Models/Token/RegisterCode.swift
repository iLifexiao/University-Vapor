//
//  RegisterCode.swift
//  App
//
//  Created by 肖权 on 2018/11/11.
//

import Vapor
import FluentPostgreSQL

// 注册码
final class RegisterCode: PostgreSQLModel {
    var id: Int?
    var code: String // 5位(数字+英文)
    var usedLimit: Int // 默认5次
    
    var status: Int?
    var createdAt: TimeInterval?
    var updatedAt: TimeInterval?
    
    init(id: Int? = nil, code: String, usedLimit: Int) {
        self.id = id
        self.code = code
        self.usedLimit = usedLimit
    }
}

extension RegisterCode: PostgreSQLMigration { }
extension RegisterCode: Content { }
extension RegisterCode: Parameter { }
