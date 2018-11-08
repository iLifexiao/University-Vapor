//
//  ShootAndPrint.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class ShootAndPrint: PostgreSQLModel {
    var id: Int?
    
    var name: String
    var imageURL: String
    var introduce: String
    var content: String
    var time: TimeInterval
    var site: String
    var phone: String
    var wechat: String?
    var qq: String?
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    
    
    init(id: Int? = nil, name: String, imageURL: String, introduce: String, content: String, time: TimeInterval, site: String, phone: String, wechat: String?, qq: String?, status: Int = 1) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.introduce = introduce
        self.content = content
        self.time = time
        self.site = site
        self.phone = phone
        self.wechat = wechat
        self.qq = qq
        self.status = status
    }
}

extension ShootAndPrint: PostgreSQLMigration { }
extension ShootAndPrint: Content { }
extension ShootAndPrint: Parameter { }

