//
//  Race.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Race: PostgreSQLModel {
    var id: Int?
    
    var imageURL: String
    var name: String
    var content: String
    var time: String
    var type: String
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    
    init(id: Int? = nil, imageURL: String, name: String, content: String, time: String, type: String, status: Int = 1) {
        self.id = id
        self.imageURL = imageURL
        self.name = name
        self.content = content
        self.time = time
        self.type = type
        self.status = status
    }
}

extension Race: PostgreSQLMigration { }
extension Race: Content { }
extension Race: Parameter { }
