//
//  Holiday.swift
//  App
//
//  Created by 肖权 on 2018/11/25.
//

import Vapor
import FluentPostgreSQL

final class Holiday: PostgreSQLModel {
    var id: Int?
    
    var name: String // 元旦
    var time: String // 01-01
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 发布时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, name: String, time: String, status: Int = 1) {
        self.id = id
        self.name = name
        self.time = time
        self.status = status
    }
}

extension Holiday: PostgreSQLMigration { }
extension Holiday: Content { }
extension Holiday: Parameter { }

