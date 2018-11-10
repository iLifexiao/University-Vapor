//
//  Academic.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Academic: PostgreSQLModel {
    var id: Int?
    
    var title: String
    var content: String
    var time: String
    var type: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    init(id: Int? = nil, title: String, content: String, time: String, type: String, status: Int? = 1) {
        self.id = id
        self.title = title
        self.content = content
        self.time = time
        self.type = type
        self.status = status
    }
}

extension Academic: PostgreSQLMigration { }
extension Academic: Content { }
extension Academic: Parameter { }
