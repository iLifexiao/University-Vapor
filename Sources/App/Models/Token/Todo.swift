import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class Todo: PostgreSQLModel {
    /// The unique identifier for this `Todo`.
    var id: Int?

    /// A title describing what this `Todo` entails.
    var title: String
    
    /// 默认时间戳，采用Optional表示
    var createdAt: TimeInterval?

    /// Creates a new `Todo`.
    init(id: Int? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Todo: PostgreSQLMigration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Todo: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Todo: Parameter { }
