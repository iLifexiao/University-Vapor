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
        group.post(User.RegisterUser.self, at: "register", use: register)
        group.post(User.self, at: "login", use: login)
        group.post(User.UserNewPwd.self, at: "changepwd", use: changePassword)
        group.post(User.LostPwd.self, at: "lostpwd", use: lostPassword)
        
        // 用户相关的信息 get
        group.get(User.parameter, "userstatus", use: getUserStatus)
        group.get(User.parameter, "userinfo", use: getUserInfo)
        group.get(User.parameter, "student", use: getStudent)
        group.get(User.parameter, "student", "lesson", use: getStudentLesson)
        group.get(User.parameter, "student", "grade", use: getStudentGrade)
        group.get(User.parameter, "focus", use: getFocus)
        group.get(User.parameter, "fans", use: getFans)
        group.get(User.parameter, "fans", "count", use: getFansCount)
        group.get(User.parameter, "collections", use: getCollections)
        group.get(User.parameter, "collections", "essay", use: getEssayCollections)
        group.get(User.parameter, "collections", "count", use: getCollectionsCount)
        group.get(User.parameter, "honors", use: getHonors)
        group.get(User.parameter, "messages", use: getMessages)
        group.get(User.parameter, "messages", "count", use: getMessagesCount)
        group.get(User.parameter, "sendmessages", use: getSendMessages)
        group.get(User.parameter, "recmessages", use: getRecMessages)
        group.get(User.parameter, "resources", use: getResources)
        group.get(User.parameter, "essays", use: getEssays)
        group.get(User.parameter, "essays", "count", use: getEssaysCount)
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
    func getOne(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // Map: 表示闭包里面的返回值 非Future
        // flatMap: 闭包里面的返回值 为Future
        // 闭包将一定会，返回的值将会执行闭包里面的代码(解包出的数据非Future)
        
        // 将从数据库查询到的用户（Future），转变为返回JSON格式(Future)，所以这里使用flatMap
        return try req.parameters.next(User.self).flatMap{ user in
            // encode(for: req)，将返回一个Future
            return try ResponseJSON<User>(message: "获取用户帐号成功", data: user).encode(for: req)
        }
    }
    
    // register/
    func register(_ req: Request, user: User.RegisterUser) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        // 查询用户
        let fetchedUser =  User.query(on: req).filter(\.account == user.account).first()
        return fetchedUser.flatMap { existingUser in
            guard existingUser == nil else {
                return try ResponseJSON<Empty>(status: .userExist).encode(for: req)
            }
            
            let registerCode = RegisterCode.query(on: req).filter(\.code == user.code).first()
            return registerCode.flatMap { existCode in
                // 注册码错误
                guard existCode != nil else {
                    return try ResponseJSON<Empty>(status: .registerCodeInvalid).encode(for: req)
                }
                // 使用次数耗尽
                var limitCount = existCode!.usedLimit
                guard limitCount > 0 else {
                    return try ResponseJSON<Empty>(status: .registerCodeInvalid).encode(for: req)
                }
                // 次数-1
                limitCount -= 1
                existCode!.usedLimit = limitCount
                return existCode!.save(on: req).flatMap { _ in
                    // 自动加盐的哈希算法，可以通过verify(_:created:)解密
                    let hasher = try req.make(BCryptDigest.self)
                    let passwordHashed = try hasher.hash(user.password)
                    let newUser = User(account: user.account, password: passwordHashed)
                    newUser.createdAt = Date().timeIntervalSince1970 //转换为非Future值，所以用Map
                    
                    // 注册用户的帐号完成后，需要完成用户信息的默认生成
                    return newUser.save(on: req).flatMap{ storedUser in
                        // 生成随机图片
                        let randomInt = try OSRandom().generate(UInt.self)
                        let random0to11 = randomInt % 12 // 生成[0~11]的随机数
                        let randomImage = "/image/head/" + String(random0to11) + ".jpg"
                        // 用户名称
                        let userName = "用户" + storedUser.account
                        let userInfo = UserInfo(userID: try storedUser.requireID(), nickname: userName, profilephoto: randomImage)
                        userInfo.createdAt = Date().timeIntervalSince1970
                        return userInfo.save(on: req).flatMap { userInfo in
                            return try ResponseJSON<UserInfo>(message: "用户注册成功", data: userInfo).encode(for: req)
                        }
                    }
                }
            }                        
        }
    }
    
    // login/
    // 登录成功，返回用户信息（前台需要自行保存用户帐号信息）
    func login(_ req: Request, user: User) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return User.query(on: req).filter(\.account == user.account).first().flatMap { fetchedUser in
            // 避免查找失败，执行下面的程序
            guard let existingUser = fetchedUser else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            
            // 检查用户状态，禁止用户登录
            guard existingUser.status != 0 else {
                return try ResponseJSON<Empty>(status: .error, message: "用户被禁止登录").encode(for: req)
            }
            
            // 解码password
            let hasher = try req.make(BCryptDigest.self)
            // 解码成功
            if try hasher.verify(user.password, created: existingUser.password) {
                return try existingUser.userInfo.query(on: req).first().flatMap { userInfo in
                    return try ResponseJSON<UserInfo>(message: "用户登录成功", data: userInfo).encode(for: req)
                }
            } else {
                // 失败抛认证失败
                return try ResponseJSON<Empty>(status: .accountOrPwdError).encode(for: req)
            }
        }
    }
    
    // 修改密码 changepwd/
    // 通过创建一个单独的结构体，来完成数据上传解析
    func changePassword(_ req: Request, user: User.UserNewPwd) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return User.query(on: req).filter(\.account == user.account).first().flatMap { fetchedUser in
            guard let existingUser = fetchedUser else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            let hasher = try req.make(BCryptDigest.self)
            if try hasher.verify(user.password, created: existingUser.password) {
                let passwordHashed = try hasher.hash(user.newPassword)
                existingUser.password = passwordHashed
                return existingUser.save(on: req).flatMap { _ in
                    return try ResponseJSON<Empty>(status: .ok).encode(for: req)
                }
                
            } else {
                return try ResponseJSON<Empty>(status: .passwordError).encode(for: req)
            }
        }
    }
    
    // lostPassword
    func lostPassword(_ req: Request, user: User.LostPwd) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return User.query(on: req).filter(\.account == user.account).first().flatMap { fetchedUser in
            guard let existingUser = fetchedUser else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            
            let userCode = UserCode.query(on: req).filter(\.code == user.code).first()
            return userCode.flatMap { existCode in
                // 修改码错误
                guard existCode != nil else {
                    return try ResponseJSON<Empty>(status: .userCodeInvalid).encode(for: req)
                }
                let hasher = try req.make(BCryptDigest.self)
                let passwordHashed = try hasher.hash(user.password)
                existingUser.password = passwordHashed
                                
                return existingUser.save(on: req).flatMap{ _ in
                    return try ResponseJSON<Empty>(status: .ok).encode(for: req)
                }
            }
        }
    }
    
    
    // 通过帐号查找用户
    func searchHandler(_ req: Request) throws -> Future<[User]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return User.query(on: req).filter(\.account == searchTerm).all()
     }
 
    
    
    // MARK: 用户相关信息API
    
    // 获取用户状态
    func getUserStatus(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            if user.status == 1 {
                return try ResponseJSON<Empty>(status: .ok, message: "用户帐号状态正常").encode(for: req)
            } else {
                return try ResponseJSON<Empty>(status: .error, message: "帐号被封禁").encode(for: req)
            }
        }
    }
    
    
    // 1:1 的需要采用以下方式来获取
    // 获得用户的信息 /id/userinfo
    func getUserInfo(_ req: Request) throws -> Future<UserInfo> {
        _ = try req.requireAuthenticated(APIUser.self)
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
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: Student.self) { user in
            return try user.student.query(on: req).first().map(to: Student.self) { student in
                guard let student = student else {
                    throw Abort(HTTPStatus.notFound, reason: "用户还未绑定学号")
                }
                return student
            }
        }
    }
    
    // 获得用户绑定的学生的课程 /id/student/lesson
    func getStudentLesson(_ req: Request) throws -> Future<[Lesson]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Lesson].self) { user in
            return try user.student.query(on: req).first().flatMap(to: [Lesson].self) { student in
                guard let student = student else {
                    throw Abort(HTTPStatus.notFound, reason: "用户还未绑定学号")
                }
                return try student.lessons.query(on: req).all()
            }
        }
    }
    
    // 获得用户绑定的学生的课程的成绩 /id/student/grade
    func getStudentGrade(_ req: Request) throws -> Future<[LessonGrade]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [LessonGrade].self) { user in
            return try user.student.query(on: req).first().flatMap(to: [LessonGrade].self) { student in
                guard let student = student else {
                    throw Abort(HTTPStatus.notFound, reason: "用户还未绑定学号")
                }
                return try student.grades.query(on: req).all()
            }
        }
    }
    
    // 1:m的则可以使用以下方法
    // 获得我的好友(我关注的) /id/focus
    func getFocus(_ req: Request) throws -> Future<[UserInfo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            try user.focus.query(on: req).all().flatMap(to: [UserInfo].self) { friends in
                // 等待获取到所有的值
                var userInfos: [Future<UserInfo>] = []
                for friend in friends {
                    userInfos.append(UserInfo.query(on: req).filter(\.userID == friend.focusUserID).first().unwrap(or: Abort(HTTPStatus.notFound)))
                }
                return userInfos.flatten(on: req)
            }
        }
    }
    
    // 获得我的粉丝（关注我的） /id/fans
    func getFans(_ req: Request) throws -> Future<[UserInfo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            return try user.fans.query(on: req).all().flatMap(to: [UserInfo].self) { fans in
                // 等待获取到所有的值
                var userInfos: [Future<UserInfo>] = []
                for fan in fans {
                    // 解包
                    userInfos.append(UserInfo.query(on: req).filter(\.userID == fan.userID).first().unwrap(or: Abort(HTTPStatus.notFound)))
                }
                return userInfos.flatten(on: req)
            }
        }
    }
    
    // 获得我的粉丝数量（关注我的） /id/fans/count
    func getFansCount(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            return try user.fans.query(on: req).filter(\.status != 0).all().flatMap { fans in
                let info = InfoCount(key: "fans", value: fans.count)
                return try ResponseJSON<InfoCount>(data: info).encode(for: req)
            }
        }
    }
    
    // 获得我的收藏 /id/collections
    func getCollections(_ req: Request) throws -> Future<[Collection]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Collection].self) { user in
            try user.collections.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的收藏的文章 /id/collections/essay
    func getEssayCollections(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            try user.collections.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all().flatMap { collections in
                var essays: [Future<Essay>] = []
                for collection in collections {
                    essays.append(Essay.find(collection.collectionID, on: req).unwrap(or: Abort(HTTPStatus.notFound)))
                }
                return essays.flatten(on: req)
            }
        }
    }
    
    // 获得我的收藏数量 /id/collections/count
    func getCollectionsCount(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            try user.collections.query(on: req).filter(\.status != 0).all().flatMap { collections in
                let info = InfoCount(key: "collections", value: collections.count)
                return try ResponseJSON<InfoCount>(data: info).encode(for: req)
            }
        }
    }
    
    // 获得我的荣耀 /id/honor
    func getHonors(_ req: Request) throws -> Future<[Honor]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Honor].self) { user in
            try user.honors.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的信息 /id/messages
    func getMessages(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.messages.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的信息数量 /id/messages/count
    func getMessagesCount(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            try user.messages.query(on: req).filter(\.status != 0).all().flatMap { messages in
                let info = InfoCount(key: "messages", value: messages.count)
                return try ResponseJSON<InfoCount>(data: info).encode(for: req)
            }
        }
    }

    
    // 获得我的已发信息 /id/sendmessages
    func getSendMessages(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.sendMessages.query(on: req).filter(\.userID == user.id!).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的发送信息 /id/recmessages
    func getRecMessages(_ req: Request) throws -> Future<[Message]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Message].self) { user in
            try user.recMessages.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的资源 /id/resources
    func getResources(_ req: Request) throws -> Future<[Resource]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Resource].self) { user in
            try user.resources.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的文章(倒序) /id/essays
    func getEssays(_ req: Request) throws -> Future<[Essay]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Essay].self) { user in
            try user.essays.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的文章的数量 /id/essays/count
    func getEssaysCount(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap { user in
            try user.essays.query(on: req).filter(\.status != 0).all().flatMap(to: Response.self) { essays in
                let info = InfoCount(key: "essays", value: essays.count)
                return try ResponseJSON<InfoCount>(data: info).encode(for: req)
            }
        }
    }
    
    // 获得我的书籍 /id/books
    func getBooks(_ req: Request) throws -> Future<[Book]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Book].self) { user in
            try user.books.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的问题 /id/questions
    func getQuestions(_ req: Request) throws -> Future<[Question]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Question].self) { user in
            try user.questions.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的回答 /id/answers
    func getAnswers(_ req: Request) throws -> Future<[Answer]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Answer].self) { user in
            try user.answers.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的经验 /id/experiences
    func getExperiences(_ req: Request) throws -> Future<[Experience]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Experience].self) { user in
            try user.experiences.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的评论 /id/comments
    func getComments(_ req: Request) throws -> Future<[Comment]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [Comment].self) { user in
            try user.comments.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的失物招领 /id/lostandfounds
    func getLostAndFounds(_ req: Request) throws -> Future<[LostAndFound]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [LostAndFound].self) { user in
            try user.lostAndFounds.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
    
    // 获得我的闲置物品 /id/idlegoods
    func getIdleGoods(_ req: Request) throws -> Future<[IdleGood]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(User.self).flatMap(to: [IdleGood].self) { user in
            try user.idleGoods.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
        }
    }
}
