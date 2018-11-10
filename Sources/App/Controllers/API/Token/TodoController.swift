import Vapor

/// Controls basic CRUD operations on `Todo`s.
final class TodoController: RouteCollection {
    
    // 路由分组
    func boot(router: Router) throws {
        let todoRouter = router.grouped("api", "v1", "todos")
        todoRouter.get(Todo.parameter, use: aTodo)
        todoRouter.get(use: index)
        todoRouter.post(Todo.self, use: create)
        todoRouter.patch(Todo.parameter, use: patch)
        todoRouter.delete(Todo.parameter, use: delete)
    }
}

// 使用扩展分离路由和处理逻辑
extension TodoController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Todo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Todo.query(on: req).all()
    }
    
    func aTodo(_ req: Request) throws -> Future<Todo> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Todo.self)
    }
    
    /// Saves a decoded `Todo` to the database.
    // 使用Grouned，Post中，需要将提交参数写在操作的函数里面
    func create(_ req: Request, todo: Todo) throws -> Future<Todo> {
        _ = try req.requireAuthenticated(APIUser.self)
        todo.createdAt = Date().timeIntervalSince1970
        return todo.save(on: req)
    }
    
    // 更新Todo的标题
    func patch(_ req: Request) throws -> Future<Todo> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Todo.self).flatMap { todo in
            return try req.content.decode(Todo.self).flatMap { newTodo in
                todo.title = newTodo.title
                return todo.save(on: req)
            }
        }
    }
    
    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Todo.self).flatMap { todo in
            return todo.delete(on: req)
            }.transform(to: .ok)
    }
}

