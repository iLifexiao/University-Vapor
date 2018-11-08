//
//  Student.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Student: PostgreSQLModel {
    var id: Int?
    var userID: User.ID
    
    var number: String // 学号
    var password: String // 学籍密码
    var name: String // 姓名
    var sex: String // 性别
    var age: Int // 年龄
    var school: String // 学校
    var major: String // 专业
    var year: String // 入学年份
    var remark: String? // 备注
    
    init(id: Int? = nil, userID: User.ID,  number: String, password: String, name: String, sex: String, age: Int, school: String, major: String, year: String) {
        self.id = id
        self.userID = userID
        self.number = number
        self.password = password
        self.name = name
        self.sex = sex
        self.age = age
        self.school = school
        self.major = major
        self.year = year
    }
}

// 表示 Student 的父母是 User
extension Student {
    var user: Parent<Student, User> {
        return parent(\.userID)
    }
}

extension Student: PostgreSQLMigration { }
extension Student: Content { }
extension Student: Parameter { }
