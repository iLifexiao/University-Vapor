//
//  LostAndFound.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class LostAndFound: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var imageURL: [String]? // 上传 0~9张的图片
    var title: String
    var content: String
    var time: TimeInterval
    var site: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, imageURL: [String]?, title: String, content: String, time: TimeInterval, site: String, status: Int? = 1, remark: String?) {
        self.id = id
        self.userID = userID
        self.imageURL = imageURL
        self.title = title
        self.content = content
        self.time = time
        self.site = site
        self.remark = remark
        self.status = status
    }
}

extension LostAndFound {
    var user: Parent<LostAndFound, User> {
        return parent(\.userID)
    }
}

extension LostAndFound: PostgreSQLMigration { }
extension LostAndFound: Content { }
extension LostAndFound: Parameter { }
