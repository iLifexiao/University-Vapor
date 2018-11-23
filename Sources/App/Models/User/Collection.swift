//
//  Collection.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Collection: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var collectionID: Int
    var type: String // 收藏的类型[Resource、Essay、CampusNews、Book、Question、Answer、Experience]
    
    var status: Int? // 状态[0, 1] = [失效, 正常]
    var createdAt: TimeInterval? // 收藏时间
    
    
    init(id: Int? = nil, userID: User.ID, collectionID: Int, type: String, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.collectionID = collectionID
        self.type = type
        self.status = status
    }
}

extension Collection {    
    struct DelInfo: Content {
        var userID: Int
        var collectionID: Int
    }
    
    var user: Parent<Collection, User> {
        return parent(\.userID)
    }
}

extension Collection: PostgreSQLMigration { }
extension Collection: Content { }
extension Collection: Parameter { }

