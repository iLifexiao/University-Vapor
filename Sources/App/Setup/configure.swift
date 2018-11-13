import Vapor
import Authentication
import FluentPostgreSQL
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // 注册数据库驱动
    try services.register(FluentPostgreSQLProvider())
    // 配置数据库
    var databasesConfig = DatabasesConfig()
    
    try databases(config: &databasesConfig)
    services.register(databasesConfig)    
    
    // 注册路由
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // 注册Leaf
    let leafProvider = LeafProvider()
    try services.register(leafProvider)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    // 注册Auth
    try services.register(AuthenticationProvider())
    
    /// 注册中间组件
    var middlewaresConfig = MiddlewareConfig()
    try middlewares(config: &middlewaresConfig)
    services.register(middlewaresConfig)            
    
    /// 配置数据库迁移
    var migrations = MigrationConfig()
    try migrate(migrations: &migrations)
    services.register(migrations)
    
    // 配置端口 ip
    var nioServerConfig = NIOServerConfig.default()
    nioServerConfig.hostname = "0.0.0.0"
//    nioServerConfig.port = 8080
    services.register(nioServerConfig)
}
