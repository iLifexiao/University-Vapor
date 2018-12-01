//
//  IdleGood.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class IdleGood: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var imageURLs: [String]? // 可以上传 0~9 图片，最多9张
    var title: String
    var content: String
    var originalPrice: Float
    var price: Float
    var type: String
    
    var status: Int? // 状态[0, 1, 2] = [下架, 正常, 删除]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    init(id: Int? = nil, userID: User.ID, imageURLs: [String]?, title: String, content: String, originalPrice: Float, price: Float, type: String, status: Int? = 1) {
        self.id = id
        self.userID = userID
        self.imageURLs = imageURLs
        self.title = title
        self.content = content
        self.originalPrice = originalPrice
        self.price = price
        self.type = type
        self.status = status
    }
}

extension IdleGood: Mappable {
    func toDictionary() -> [String : Any] {
        return [
            "id": id ?? 0,
            "userID": userID,
            
            "imageURLs": imageURLs ?? [""],
            "title": title,
            "content": content,
            "originalPrice": originalPrice,
            "price": price,
            "type": type,
            
            "status": status ?? 1,            
            "createdAt": createdAt ?? 0,
            "updatedAt": updatedAt ?? 0
        ]
    }
}

extension IdleGood {
    var user: Parent<IdleGood, User> {
        return parent(\.userID)
    }
}

extension IdleGood: PostgreSQLMigration { }
extension IdleGood: Content { }
extension IdleGood: Parameter { }

