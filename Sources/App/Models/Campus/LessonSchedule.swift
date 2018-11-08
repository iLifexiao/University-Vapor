//
//  LessonSchedule.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class LessonSchedule: PostgreSQLModel {
    var id: Int?
    var studentID: Student.ID
    
    var year: String
    var term: String
    
    var status: Int // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    
    init(id: Int? = nil, studentID: Student.ID, year: String, term: String, remark: String?, status: Int = 1) {
        self.id = id
        self.studentID = studentID
        self.year = year
        self.term = term
        self.remark = remark
        self.status = status
    }
}

extension LessonSchedule {
    var student: Parent<LessonSchedule, Student> {
        return parent(\.studentID)
    }
}

extension LessonSchedule: PostgreSQLMigration { }
extension LessonSchedule: Content { }
extension LessonSchedule: Parameter { }
