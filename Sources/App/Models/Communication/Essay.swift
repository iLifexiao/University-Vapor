//
//  Essay.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Essay: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
        
    var title: String
    var content: String
    var type: String // 日常、生活、教程等等
    
    var commentCount: Int?
    var likeCount: Int?
    var readCount: Int?
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, userID: User.ID, title: String, content: String, type: String, commentCount: Int? = 0, likeCount: Int? = 0, readCount: Int? = 0, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.title = title
        self.content = content
        self.type = type
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.readCount = readCount
        self.status = status
    }
}

extension Essay: Mappable {
    func toDictionary() -> [String : Any] {
        return [
            "id": id ?? 0,
            "userID": userID,
            "title": title,
            "content": content,
            "type": type,
            "commentCount": commentCount ?? 0,
            "likeCount": likeCount ?? 0,
            "readCount": readCount ?? 0,
            "status": status ?? 1,
            "createdAt": createdAt ?? 0,
            "updatedAt": updatedAt ?? 0
        ]
    }
}

extension Essay {
    // 获取列表里的ID信息
    struct IDList: Content {
        var ids: [Int]
    }
    
    var user: Parent<Essay, User> {
        return parent(\.userID)
    }
}

extension Essay: PostgreSQLMigration { }
extension Essay: Content { }
extension Essay: Parameter { }

