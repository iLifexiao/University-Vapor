//
//  UserInfo.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class UserInfo: PostgreSQLModel {
    var id: Int?
    var userID: User.ID // 外键
    
    var profilephoto: String // 默认：「/image/7.jpg」
    var sex: String // 性别「保密」
    var age: Int // 年龄「18」
    var phone: String? // 电话
    var email: String? // 邮箱
    var introduce: String // 自我介绍「这个人很cool，还没有介绍」
    var type: String // 默认[普通, SVIP]
    var remark: String? // 备注
    
    init(id: Int? = nil, userID: User.ID, profilephoto: String = "/image/7.jpg", sex: String = "保密", age: Int = 18, phone: String, email: String, introduce: String = "这个人很cool，还没有介绍", type: String = "普通") {
        self.id = id
        self.userID = userID
        self.profilephoto = profilephoto
        self.sex = sex
        self.age = age
        self.phone = phone
        self.email = email
        self.introduce = introduce
        self.type = type
    }
}

extension UserInfo {
    // 表示 UserInfo 的父母是 User
    var user: Parent<UserInfo, User> {
        return parent(\.userID)
    }
}

extension UserInfo: PostgreSQLMigration { }
extension UserInfo: Content { }
extension UserInfo: Parameter { }
