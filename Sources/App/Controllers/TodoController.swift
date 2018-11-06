import Vapor

/// Controls basic CRUD operations on `Todo`s.
final class TodoController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Todo]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Todo.query(on: req).all()
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> Future<Todo> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.content.decode(Todo.self).flatMap { todo in
            return todo.save(on: req)
        }
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
