//
//  User.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class User: PostgreSQLModel {
    var id: Int?
    var account: String // 电话，用于注册
    var password: String // 加密的密码
        
    var status: Int? // 状态[0, 1, 2] = [禁登、正常、注销]
    var createdAt: TimeInterval? // 注册时间
    
    // 便于帐号登录注册，使用默认参数提供不重要的信息
    init(id: Int? = nil, account: String, password: String, status: Int? = 1) {
        self.id = id
        self.account = account
        self.password = password        
        self.status = status        
    }
}

extension User {
    // 更新帐号密码
    struct UserNewPwd: Content {        
        let account: String
        let password: String
        let newPassword: String
    }
    // 注册帐号密码
    struct RegisterUser: Content {
        let account: String
        let password: String
        let code: String
    }
    // 丢失帐号密码
    struct LostPwd: Content {
        let account: String
        let password: String
        let code: String
    }
    // 用户信息1:1
    var userInfo: Children<User, UserInfo> {
        return children(\.userID)
    }
    // 绑定的学生1:1
    var student: Children<User, Student> {
        return children(\.userID)
    }
    // 关注的好友1:m
    var focus: Children<User, Focus> {
        return children(\.userID)
    }
    // 粉丝
    var fans: Children<User, Focus> {
        return children(\.focusUserID)
    }
    // 收藏1:m
    var collections: Children<User, Collection> {
        return children(\.userID)
    }
    // 荣耀1:m
    var honors: Children<User, Honor> {
        return children(\.userID)
    }
    // 信息1:m（包含发送的和接收的）
    var messages: Children<User, Message> {
        return children(\.userID)
    }
    // 发送的信息
    var sendMessages: Children<User, Message> {
        return children(\.fromUserID)
    }
    // 接收的信息
    var recMessages: Children<User, Message> {
        return children(\.toUserID)
    }
    // 资源1:m
    var resources: Children<User, Resource> {
        return children(\.userID)
    }
    // 文章1:m
    var essays: Children<User, Essay> {
        return children(\.userID)
    }
    // 书籍1:m
    var books: Children<User, Book> {
        return children(\.userID)
    }
    // 问题1:m
    var questions: Children<User, Question> {
        return children(\.userID)
    }
    // 回答1:m
    var answers: Children<User, Answer> {
        return children(\.userID)
    }
    // 经验1:m
    var experiences: Children<User, Experience> {
        return children(\.userID)
    }
    // 评论1:m（所有的评论「文章、新闻、书籍等等」）
    var comments: Children<User, Comment> {
        return children(\.userID)
    }
    // 失物招领1:m
    var lostAndFounds: Children<User, LostAndFound> {
        return children(\.userID)
    }
    // 闲置物品
    var idleGoods: Children<User, IdleGood> {
        return children(\.userID)
    }
}

// 数据库自定义配置
extension User: PostgreSQLMigration { }
extension User: Content { }
extension User: Parameter { }
