//
//  databases.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

public func databases(config: inout DatabasesConfig) throws {
    /// 配置数据库
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "127.0.0.1",
        port: 5432,
        username: "iLife",
        database: "vapor",
        password: nil
    )
    config.add(database: PostgreSQLDatabase(config: postgresqlConfig), as: .psql)
}

