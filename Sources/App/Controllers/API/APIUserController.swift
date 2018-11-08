//
//  APIUserController.swift
//  App
//
//  Created by 肖权 on 2018/9/14.
//

import Vapor
import Crypto
import Random
import FluentPostgreSQL

final class APIUserController {
    func register(_ req: Request) throws -> Future<APIUser.UserPublic> {
        return try req.content.decode(APIUser.self).flatMap { user in
            // 自动加盐的哈希算法，可以通过verify(_:created:)解密
            let hasher = try req.make(BCryptDigest.self)
            let passwordHashed = try hasher.hash(user.password)
            let newUser = APIUser(name: user.name, email: user.email, password: passwordHashed)
            
            return newUser.save(on: req).map { storedUser in
                return APIUser.UserPublic(
                    // 获取保存到数据库中的ID号
                    id: try storedUser.requireID(),
                    name: storedUser.name,
                    email: storedUser.email
                )
            }
        }
    }
    
    func login(_ req: Request) throws -> Future<APIToken> {
        return try req.content.decode(APIUser.self).flatMap { user in
            return APIUser.query(on: req).filter(\.email == user.email).first().flatMap { fetchedUser in
                // 避免查找失败，执行下面的程序
                guard let existingUser = fetchedUser else {
                    throw Abort(HTTPStatus.notFound)
                }
                
                // 解码password
                let hasher = try req.make(BCryptDigest.self)
                // 解码成功
                if try hasher.verify(user.password, created: existingUser.password) {
                    // 尝试获取，每次登录的时候都会重新获取token
                    return try APIToken
                        .query(on: req)
                        .filter(\APIToken.userId, .equal, existingUser.requireID())
                        .delete()
                        .flatMap { _ in
                            // 生成随机的token
                            let tokenString = try URandom().generateData(count: 32).base64EncodedString()
                            let token = try APIToken(token: tokenString, userId: existingUser.requireID())
                            return token.save(on: req)
                    }
                } else {
                    // 失败抛认证失败
                    throw Abort(HTTPStatus.unauthorized)
                }
            }
        }
    }
    
    // 检测是否认证成功
    func profile(_ req: Request) throws -> Future<String> {
        let user = try req.requireAuthenticated(APIUser.self)
        return req.future("Welcome \(user.name)")
    }
    
    // 删除用户的认证
    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(APIUser.self)
        return try APIToken
            .query(on: req)
            .filter(\APIToken.userId, .equal, user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
}
