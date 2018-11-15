//
//  StudentController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class StudentController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "student")
        group.get("all", use: getAllHandler)
        group.get(Student.parameter, use: getHandler)
        
        group.post(Student.self, use: createHandler)
        group.post(Student.Account.self, at: "bind", use: bindUserHandler)
        group.patch(Student.parameter, use: updateHandler)
        group.delete(Student.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("first", use: getFirstHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension StudentController {
    func getAllHandler(_ req: Request) throws -> Future<[Student]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Student.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Student> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Student.self)
    }
    
    func createHandler(_ req: Request, student: Student) throws -> Future<Student> {
        _ = try req.requireAuthenticated(APIUser.self)
        student.createdAt = Date().timeIntervalSince1970
        return student.save(on: req)
    }
    
    // 用户绑定学生帐号
    func bindUserHandler(_ req: Request, student: Student.Account) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Student.query(on: req).filter(\.number == student.number).filter(\.password == student.password).first().flatMap { stu in
            // 确保查询成功
            guard let stu = stu else {
                return try ResponseJSON<Empty>(status: .error, message: "学生不存在").encode(for: req)
            }
            stu.userID = student.userID
            return stu.save(on: req).flatMap { bindStu in
                return try ResponseJSON<Student>(status: .ok, message: "绑定成功", data: bindStu).encode(for: req)
            }
        }
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Student> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Student.self, req.parameters.next(Student.self), req.content.decode(Student.self)) { stuent, newStuent in
            stuent.number = newStuent.number
            stuent.password = newStuent.password
            stuent.name = newStuent.name
            stuent.sex = newStuent.sex
            stuent.age = newStuent.age
            stuent.school = newStuent.school
            stuent.major = newStuent.major
            stuent.year = newStuent.year
            stuent.updatedAt = Date().timeIntervalSince1970
            return stuent.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Student.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Student]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Student.query(on: req).group(.or) { or in
            or.filter(\.number == searchTerm)
            or.filter(\.name == searchTerm)
            or.filter(\.school == searchTerm)
            or.filter(\.major == searchTerm)
            }.all()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Student> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Student.query(on: req).first().map(to: Student.self) { student in
            guard let student = student else {
                throw Abort(.notFound)
            }
            return student
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Student]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Student.query(on: req).sort(\.number, .ascending).all()
    }
}
