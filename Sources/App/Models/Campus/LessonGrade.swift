//
//  LessonGrade.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class LessonGrade: PostgreSQLModel {
    var id: Int?
    var studentID: Student.ID
    var scheduleID: LessonSchedule.ID
    
    var no: String
    var name: String
    var type: String
    var credit: Float
    var gradePoint: Float
    var grade: Float
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var remark: String? // 备注
    var createdAt: TimeInterval? // 创建时间    
    var updatedAt: TimeInterval? // 更新时间
    
    
    init(id: Int? = nil, studentID: Student.ID, scheduleID: LessonSchedule.ID, no: String, name: String, type: String, credit: Float, gradePoint: Float, grade: Float, remark: String?, status: Int? = 1) {
        self.id = id
        self.studentID = studentID
        self.scheduleID = scheduleID
        self.no = no
        self.name = name
        self.type = type
        self.credit = credit
        self.gradePoint = gradePoint
        self.grade = grade
        self.remark = remark
        self.status = status
    }
}

extension LessonGrade {
    var student: Parent<LessonGrade, Student> {
        return parent(\.studentID)
    }
    
    var schedule: Parent<LessonGrade, LessonSchedule> {
        return parent(\.scheduleID)
    }
}

extension LessonGrade: PostgreSQLMigration { }
extension LessonGrade: Content { }
extension LessonGrade: Parameter { }
