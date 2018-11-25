//
//  migrate.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

// 当你在模型里面修改后会自动更新数据库
public func migrate(migrations: inout MigrationConfig) throws {
    // Auth
    migrations.add(model: APIUser.self, database: .psql)
    migrations.add(model: APIToken.self, database: .psql)
    migrations.add(model: RegisterCode.self, database: .psql)
    migrations.add(model: UserCode.self, database: .psql)
    
    // Test_CRUD
    migrations.add(model: Todo.self, database: .psql)
    
    // User
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserInfo.self, database: .psql)
    migrations.add(model: Student.self, database: .psql)
    migrations.add(model: Focus.self, database: .psql)
    migrations.add(model: Collection.self, database: .psql)
    migrations.add(model: Honor.self, database: .psql)
    migrations.add(model: Message.self, database: .psql)
    
    // AD
    migrations.add(model: ADBanner.self, database: .psql)
    migrations.add(model: Notification.self, database: .psql)
    
    // Campus
    migrations.add(model: Lesson.self, database: .psql)
    migrations.add(model: LessonSchedule.self, database: .psql)
    migrations.add(model: LessonGrade.self, database: .psql)
    migrations.add(model: Race.self, database: .psql)
    migrations.add(model: Academic.self, database: .psql)
    migrations.add(model: Examination.self, database: .psql)
    migrations.add(model: Speech.self, database: .psql)
    migrations.add(model: Club.self, database: .psql)
    migrations.add(model: AddressList.self, database: .psql)
    migrations.add(model: LostAndFound.self, database: .psql)
    
    // Communication
    migrations.add(model: Resource.self, database: .psql)
    migrations.add(model: Essay.self, database: .psql)
    migrations.add(model: CampusNews.self, database: .psql)
    migrations.add(model: Book.self, database: .psql)
    migrations.add(model: Question.self, database: .psql)
    migrations.add(model: Answer.self, database: .psql)
    migrations.add(model: Experience.self, database: .psql)
    migrations.add(model: Comment.self, database: .psql)
    
    // 迁移(新增read/like、comment字段) migration
    migrations.add(migration: UpdateCampusNewsField.self, database: .psql)
    migrations.add(migration: UpdateResourceField.self, database: .psql)
    migrations.add(migration: UpdateAnswerField.self, database: .psql)
    migrations.add(migration: UpdateExperienceField.self, database: .psql)
    migrations.add(migration: UpdateBookField.self, database: .psql)
    
    
    // LifeStype
    migrations.add(model: IdleGood.self, database: .psql)
    migrations.add(model: UtilityBill.self, database: .psql)
    migrations.add(model: ShootAndPrint.self, database: .psql)
    migrations.add(model: PropertyManager.self, database: .psql)
    migrations.add(model: SchoolStore.self, database: .psql)
    migrations.add(model: PartTimeJob.self, database: .psql)
    migrations.add(model: Holiday.self, database: .psql)
}
