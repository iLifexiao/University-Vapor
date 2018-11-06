import Authentication
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// 注册数据库驱动 Register providers first
    try services.register(FluentPostgreSQLProvider())
    /// 配置数据库
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "127.0.0.1",
        port: 5432,
        username: "iLife",
        database: "vapor",
        password: nil
    )
    services.register(postgresqlConfig)
    
    // 注册路由
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // 注册Auth
    try services.register(AuthenticationProvider())
    
    /// 注册中间组件
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // 1. 跨域请求设置
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    // 2. 静态资源 Serves files from `Public/` directory
    middlewares.use(FileMiddleware.self)
    // 3. 错误处理 Catches errors and converts to HTTP response
    middlewares.use(ErrorMiddleware.self)
    
    services.register(middlewares)
    
    /// 配置数据库迁移（当你在模型里面修改后会自动更新数据库）
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .psql)
    migrations.add(model: APIUser.self, database: .psql)
    migrations.add(model: APIToken.self, database: .psql)
    services.register(migrations)
}
