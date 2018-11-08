import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("view") { req -> Future<View> in
        return try req.view().render("welcome")
    }

    // 御用创建和使用认证，后期可以移除
    let apiUserController = APIUserController()
    router.post("register", use: apiUserController.register)
    router.post("login", use: apiUserController.login)
    
    // 将中间组件添加到路由组中
    let tokenAuthenticationMiddleware = APIUser.tokenAuthMiddleware()
    let authedRoutes = router.grouped(tokenAuthenticationMiddleware)
    authedRoutes.get("profile", use: apiUserController.profile)
    authedRoutes.get("logout", use: apiUserController.logout)
    
    // Example of configuring a controller
    let todoController = TodoController()
    try authedRoutes.register(collection: todoController)
}
