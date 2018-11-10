//
//  Examination.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Examination: PostgreSQLModel {
    var id: Int?
    
    var name: String
    var year: String
    var major: String
    var time: String
    var site: String
    var numbers: Int
    var teacher: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, name: String, year: String, major: String, time: String, site: String, numbers: Int, teacher: String, remark: String?, status: Int? = 1) {
        self.id = id
        self.name = name
        self.year = year
        self.major = major
        self.time = time
        self.site = site
        self.numbers = numbers
        self.teacher = teacher
        self.remark = remark
        self.status = status
    }
}

extension Examination: PostgreSQLMigration { }
extension Examination: Content { }
extension Examination: Parameter { }

