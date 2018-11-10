//
//  Resource.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Resource: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var imageURL: String
    var name: String
    var introduce: String
    var type: String
    
    var likeCount: Int?
    var commentCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    init(id: Int? = nil, userID: User.ID, imageURL: String, name: String, introduce: String, type: String,  likeCount: Int? = 0, commentCount: Int? = 0, remark: String?, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.imageURL = imageURL
        self.name = name
        self.introduce = introduce
        self.type = type
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.remark = remark        
        self.status = status
    }
}

extension Resource {
    var user: Parent<Resource, User> {
        return parent(\.userID)
    }
}

extension Resource: PostgreSQLMigration { }
extension Resource: Content { }
extension Resource: Parameter { }

