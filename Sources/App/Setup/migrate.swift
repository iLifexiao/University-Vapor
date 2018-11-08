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
    
    // Test_CRUD
    migrations.add(model: Todo.self, database: .psql)
}
