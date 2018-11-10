//
//  UserController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import Crypto
import Random
import FluentPostgreSQL // 使用Fulent查询，需要导入该数据包

final class UserController: RouteCollection {
    
    func boot(router: Router) throws {        
        let group = router.grouped("api", "v1", "user")
        
        // 获得用户
        group.get(User.parameter, use: getOne)
        
        //search?term=
        group.get("search", use: searchHandler)
        
        // 自动解码json -> model post
        group.post(User.self, at: "register", use: register)
        group.post(User.self, at: "login", use: login)
        group.post(User.UserNewPwd.self, at: "changepwd", use: changePassword)
        
        // 用户相关的信息 get
        group.get(User.parameter, "userinfo", use: getUserInfo)
        group.get(User.parameter, "student", use: getStudent)
        group.get(User.parameter, "focus", use: getFocus)
        group.get(User.parameter, "fans", use: getFans)
        group.get(User.parameter, "collections", use: getCollections)
        group.get(User.parameter, "honors", use: getHonors)
        group.get(User.parameter, "messages", use: getMessages)
        group.get(User.parameter, "sendmessages", use: getSendMessages)
        group.get(User.parameter, "recmessages", use: getRecMessages)
        group.get(User.parameter, "resources", use: getResources)
        group.get(User.parameter, "essays", use: getEssays)
        group.get(User.parameter, "books", use: getBooks)
        group.get(User.parameter, "questions", use: getQuestions)
        group.get(User.parameter, "answers", use: getAnswers)
        group.get(User.parameter, "experiences", use: getExperiences)
        group.get(User.parameter, "comments", use: getComments)
        group.get(User.parameter, "lostandfounds", use: getLostAndFounds)
        group.get(User.parameter, "idlegoods", use: getIdleGoods)
        
    }
    
}

extension UserController {
    // 获得一个用户的信息
    func getOne(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    // register/
    func register(_ req: Request, user: User) throws -> Future<UserInfo> {
        let fetchedUser =  User.query(on: req).filter(\.account == user.account).first()
        return fetchedUser.flatMap { existingUser in
            guard existingUser == nil else {
                throw Abort(HTTPStatus.notFound, reason: "用户已存在")
            }
            
            // 自动加盐的哈希算法，可以通过verify(_:created:)解密
            let hasher = try req.make(BCryptDigest.self)
            let passwordHashed = try hasher.hash(user.password)
            let newUser = User(account: user.account, password: passwordHashed)
            newUser.createdAt = Date().timeIntervalSince1970
            
            // 注册用户的同时，需要完成用户信息的默认生成
            // 这里使用flatMap，进行两次转换
            return newUser.save(on: req).flatMap(to: UserInfo.self) { storedUser in
                // 生成随机图片
                let randomInt = try OSRandom().generate(UInt.self)
                let random0to11 = randomInt % 12 // 生成[0~11]的随机数
                let randomImage = "/image/" + String(random0to11) + ".jpg"
                // 用户名称
                let userName = "用户" + storedUser.account
                let userInfo = UserInfo(userID: try storedUser.requireID(), nickname: userName, profilephoto: randomImage)
                userInfo.createdAt = Date().timeIntervalSince1970
                return userInfo.save(on: req)
            }
        }
    }
    
    // login/
    // 登录成功，返回用户信息（前台需要自行保存用户帐号信息）
    func login(_ req: Request, user: User) throws -> Future<UserInfo> {
        return User.query(on: req).filter(\.account == user.account).first().flatMap { fetchedUser in
            // 避免查找失败，执行下面的程序
            guard let existingUser = fetchedUser else {
                throw Abort(HTTPStatus.notFound, reason: "用户不存在")
            }
            
            // 解码password
            let hasher = try req.make(BCryptDigest.self)
            // 解码成功
            if try hasher.verify(user.password, created: existingUser.password) {
                return try existingUser.userInfo.query(on: req).first().map { userInfo in
                    guard let userInfo = userInfo else {
                        throw Abort(HTTPStatus.notFound)
                    }
                    return userInfo
                }
                
            } else {
                // 失败抛认证失败
                throw Abort(HTTPStatus.unauthorized, reason: "帐号或密码错误")
            }
        }
    }
    
    // 修改密码 changepwd/
    // 通过创建一个单独的结构体，来完成数据上传解析
    func changePassword(_ req: Request, user: User.UserNewPwd) throws -> Future<HTTPResponse> {
        return User.query(on: req).filter(\.account == user.account).first().flatMap { fetchedUser in
            guard let existingUser = fetchedUser else {
                throw Abort(HTTPStatus.notFound, reason: "用户不存在")
            }
            let hasher = try req.make(BCryptDigest.self)
            if try hasher.verify(user.password, created: existingUser.password) {
                let passwordHashed = try hasher.hash(user.newPassword)
                existingUser.password = passwordHashed
                return existingUser.save(on: req).transform(to: HTTPResponse(status: .ok))
                
            } else {
                throw Abort(HTTPStatus.unauthorized, reason: "原密码错误")
            }
        }
    }

    
    
    // 通过帐号查找用户
    func searchHandler(_ req: Request) throws -> Future<[User]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return User.query(on: req).filter(\.account == searchTerm).all()
     }
 
    
    
    // MARK: 用户相关信息API
    // 1:1 的需要采用以下方式来获取
    // 获得用户的信息 /id/userinfo
    func getUserInfo(_ req: Request) throws -> Future<UserInfo> {
        return try req.parameters.next(User.self).flatMap(to: UserInfo.self) { user in
            return try user.userInfo.query(on: req).first().map(to: UserInfo.self) { userInfo in
                guard let userInfo = userInfo else {
                    throw Abort(HTTPStatus.notFound, reason: "用户信息不存在")
                }
                return userInfo
            }
        }
    }
        
    // 获得用户绑定的学生 /id/student
    func getStudent(_ req: Request) throws -> Future<Student> {
        return try req.parameters.next(User.self).flatMap(to: Student.self) { user in
            return try user.student.query(on: req).first().map(to: Student.self) { student in
                guard let student = student else {
                    throw Abort(HTTPStatus.notFound, reason: "用户还未绑定学号")
                }
                return student
            }
        }
    }
    
    // 1:m的则可以使用以下方法
    // 获得我的好友 /id/focus
    func getFocus(_ req: Request) throws -> Future<[Focus]> {
        return try req.parameters.next(User.self).flatMap(to: [Focus].self) { user in
            try user.focus.query(on: req).all()
        }
    }
    
    // 获得我的粉丝 /id/fans
    func getFans(_ req: Request) throws -> Future<[Focus]> {
        return try req.parameters.next(User.self).flatMap(to: [Focus].self) { user in
            try user.fans.query(on: req).all()
        }
    }
    
    // 获得我的收藏 /id/collections
    func getCollections(_ req: Request) throws -> Future<[Collection]> {
        return try req.parameters.next(User.self).flatMap(to: [Collection].self) { user in
            try user.collections.query(on: req).all()
        }
    }
    
    // 获得我的荣耀 /id/honor
    func getHonors(_ req: Request) throws -> Future<[Honor]> {
        return try req.parameters.next(User.self).flatMap(to: [Honor].self) { user in
            try user.honors.query(on: req).all()
        }
    }
    
    // 获得我的信息 /id/messages
    func getMessages(_ req: Request) throws -> Future<[Message]> {
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.messages.query(on: req).all()
        }
    }
    
    // 获得我的已发信息 /id/sendmessages
    func getSendMessages(_ req: Request) throws -> Future<[Message]> {
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.sendMessages.query(on: req).all()
        }
    }
    
    // 获得我的发送信息 /id/recmessages
    func getRecMessages(_ req: Request) throws -> Future<[Message]> {
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.recMessages.query(on: req).all()
        }
    }
    
    // 获得我的资源 /id/resources
    func getResources(_ req: Request) throws -> Future<[Resource]> {
        return try req.parameters.next(User.self).flatMap(to: [Resource].self) { user in
            try user.resources.query(on: req).all()
        }
    }
    
    // 获得我的文章 /id/essays
    func getEssays(_ req: Request) throws -> Future<[Essay]> {
        return try req.parameters.next(User.self).flatMap(to: [Essay].self) { user in
            try user.essays.query(on: req).all()
        }
    }
    
    // 获得我的书籍 /id/books
    func getBooks(_ req: Request) throws -> Future<[Book]> {
        return try req.parameters.next(User.self).flatMap(to: [Book].self) { user in
            try user.books.query(on: req).all()
        }
    }
    
    // 获得我的问题 /id/questions
    func getQuestions(_ req: Request) throws -> Future<[Question]> {
        return try req.parameters.next(User.self).flatMap(to: [Question].self) { user in
            try user.questions.query(on: req).all()
        }
    }
    
    // 获得我的回答 /id/answers
    func getAnswers(_ req: Request) throws -> Future<[Answer]> {
        return try req.parameters.next(User.self).flatMap(to: [Answer].self) { user in
            try user.answers.query(on: req).all()
        }
    }
    
    // 获得我的经验 /id/experiences
    func getExperiences(_ req: Request) throws -> Future<[Experience]> {
        return try req.parameters.next(User.self).flatMap(to: [Experience].self) { user in
            try user.experiences.query(on: req).all()
        }
    }
    
    // 获得我的评论 /id/comments
    func getComments(_ req: Request) throws -> Future<[Comment]> {
        return try req.parameters.next(User.self).flatMap(to: [Comment].self) { user in
            try user.comments.query(on: req).all()
        }
    }
    
    // 获得我的失物招领 /id/lostandfounds
    func getLostAndFounds(_ req: Request) throws -> Future<[LostAndFound]> {
        return try req.parameters.next(User.self).flatMap(to: [LostAndFound].self) { user in
            try user.lostAndFounds.query(on: req).all()
        }
    }
    
    // 获得我的闲置物品 /id/idlegoods
    func getIdleGoods(_ req: Request) throws -> Future<[IdleGood]> {
        return try req.parameters.next(User.self).flatMap(to: [IdleGood].self) { user in
            try user.idleGoods.query(on: req).all()
        }
    }
}
