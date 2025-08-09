import Foundation
import SQLite

public struct RecipeEntity {
    public let id: Int64
    public let name: String
    public let cuisine: String?
    public let createdAt: Date
}

public final class RecipeDAO {
    private let table = Table("recipes")
    private let id = Expression<Int64>("id")
    private let name = Expression<String>("name")
    private let cuisine = Expression<String?>("cuisine")
    private let createdAt = Expression<Date>("created_at")

    public init() {}

    public func insert(name: String, cuisine: String?) throws -> Int64 {
        return try DatabaseManager.shared.write { conn in
            let insert = table.insert(self.name <- name,
                                      self.cuisine <- cuisine,
                                      self.createdAt <- Date())
            return try conn.run(insert)
        }
    }

    public func fetchAll(orderByNewest: Bool = true) throws -> [RecipeEntity] {
        try DatabaseManager.shared.read { conn in
            let query = orderByNewest ? table.order(createdAt.desc) : table
            return try conn.prepare(query).map { row in
                RecipeEntity(id: row[id], name: row[name], cuisine: row[cuisine], createdAt: row[createdAt])
            }
        }
    }

    public func delete(id recipeId: Int64) throws {
        _ = try DatabaseManager.shared.write { conn in
            let item = table.filter(id == recipeId)
            return try conn.run(item.delete())
        }
    }

    public func updateName(id recipeId: Int64, newName: String) throws {
        _ = try DatabaseManager.shared.write { conn in
            let item = table.filter(id == recipeId)
            return try conn.run(item.update(name <- newName))
        }
    }
}
