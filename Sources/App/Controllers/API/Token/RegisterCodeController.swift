//
//  RegisterCodeController.swift
//  App
//
//  Created by 肖权 on 2018/11/11.
//

import Vapor
import FluentPostgreSQL

final class RegisterCodeController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "registercode")
        group.get("all", use: getAllHandler)
        group.get(RegisterCode.parameter, use: getHandler)
        
        group.post(RegisterCode.self, use: createHandler)
        group.patch(RegisterCode.parameter, use: updateHandler)
        group.delete(RegisterCode.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("sort", use: sortedHandler)
        
        group.get("used", use: useRegisterCode)
    }
    
}

extension RegisterCodeController {
    func getAllHandler(_ req: Request) throws -> Future<[RegisterCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return RegisterCode.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<RegisterCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(RegisterCode.self)
    }
    
    func createHandler(_ req: Request, registerCode: RegisterCode) throws -> Future<RegisterCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        let fetchedCode = RegisterCode.query(on: req).filter(\.code == registerCode.code).first()
        return fetchedCode.flatMap { existCode in
            guard existCode == nil else {
                throw Abort(HTTPStatus.notFound, reason: "注册码已存在")
            }
            registerCode.createdAt = Date().timeIntervalSince1970
            registerCode.status = 1
            return registerCode.save(on: req)
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<RegisterCode> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: RegisterCode.self, req.parameters.next(RegisterCode.self), req.content.decode(RegisterCode.self)) { registerCode, newRegisterCode in
            registerCode.code = newRegisterCode.code
            registerCode.usedLimit = newRegisterCode.usedLimit
            registerCode.updatedAt = Date().timeIntervalSince1970
            return registerCode.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(RegisterCode.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[RegisterCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return RegisterCode.query(on: req).group(.or) { or in
            or.filter(\.code == searchTerm)
        }.all()
    }
    
    // used?code=
    func useRegisterCode(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let code = req.query[String.self, at: "code"] else {
            throw Abort(.badRequest)
        }
        let registerCode = RegisterCode.query(on: req).filter(\.code == code).filter(\.status != 0).first()
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
                return try ResponseJSON<Empty>(status: .ok, message: "注册码有效").encode(for: req)
            }
            
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[RegisterCode]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return RegisterCode.query(on: req).sort(\.createdAt, .ascending).all()
    }
}

