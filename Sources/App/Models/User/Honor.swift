//
//  Honor.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Honor: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var name: String
    var rank: String
    var time: String // 获得时间
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
        
    init(id: Int? = nil, userID: User.ID, name: String, rank: String, time: String, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.name = name
        self.rank = rank
        self.time = time
        self.status = status
    }
}

extension Honor {
    var user: Parent<Honor, User> {
        return parent(\.userID)
    }
}

extension Honor: PostgreSQLMigration { }
extension Honor: Content { }
extension Honor: Parameter { }

