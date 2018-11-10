//
//  Club.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Club: PostgreSQLModel {
    var id: Int?
    
    var imageURL: String
    var name: String
    var introduce: String
    var time: TimeInterval
    var numbers: Int
    var rank: String
    var type: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
        
    init(id: Int? = nil, imageURL: String, name: String, introduce: String, time: TimeInterval, numbers: Int, rank: String, type: String, status: Int? = 1) {
        self.id = id
        self.imageURL = imageURL
        self.name = name
        self.introduce = introduce
        self.time = time
        self.numbers = numbers
        self.rank = rank
        self.type = type
        self.status = status
    }
}

extension Club: PostgreSQLMigration { }
extension Club: Content { }
extension Club: Parameter { }
