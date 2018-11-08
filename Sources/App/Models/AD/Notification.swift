//
//  Notification.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Notification: PostgreSQLModel {
    var id: Int?
    
    var title: String // 标题
    var content: String // 内容
    var type: String // 类型
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    
    
    init(id: Int? = nil, title: String, content: String, type: String, status: Int = 1) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.status = status
    }
}

extension Notification: PostgreSQLMigration { }
extension Notification: Content { }
extension Notification: Parameter { }
