//
//  Lesson.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Lesson: PostgreSQLModel {
    var id: Int?
    var studentID: Student.ID
    var scheduleID: LessonSchedule.ID
    
    var timeInWeek: String
    var timeInDay: String
    var timeInTerm: String
    var name: String
    var teacher: String
    var site: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, studentID: Student.ID, scheduleID: LessonSchedule.ID, timeInWeek: String, timeInDay: String, timeInTerm: String, name: String, teacher: String, site: String, remark: String?, status: Int? = 1) {
        self.id = id
        self.studentID = studentID
        self.scheduleID = scheduleID
        self.timeInWeek = timeInWeek
        self.timeInDay = timeInDay
        self.timeInTerm = timeInTerm
        self.name = name
        self.teacher = teacher
        self.site = site
        self.remark = remark
        self.status = status
    }
}

extension Lesson {
    var student: Parent<Lesson, Student> {
        return parent(\.studentID)
    }
    
    var schedule: Parent<Lesson, LessonSchedule> {
        return parent(\.scheduleID)
    }
}

extension Lesson: PostgreSQLMigration { }
extension Lesson: Content { }
extension Lesson: Parameter { }
