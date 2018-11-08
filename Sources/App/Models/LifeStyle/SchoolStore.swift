//
//  SchoolStore.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class SchoolStore: PostgreSQLModel {
    var id: Int?
    
    var name: String
    var imageURL: String
    var introduce: String
    var content: String
    var type: String
    var site: String
    var time: TimeInterval
    var phone: String
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    
    
    init(id: Int? = nil, name: String, imageURL: String, introduce: String, content: String, type: String, site: String, time: TimeInterval, phone: String, status: Int = 1) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.introduce = introduce
        self.content = content
        self.type = type
        self.site = site
        self.time = time
        self.phone = phone
        self.status = status
    }
}

extension SchoolStore: PostgreSQLMigration { }
extension SchoolStore: Content { }
extension SchoolStore: Parameter { }
