import Foundation
import SQLite

/// 数据库错误类型
public enum DatabaseError: Error, CustomStringConvertible {
    case notInitialized
    case migrationFailed(underlying: Error)
    case executionFailed(underlying: Error)

    public var description: String {
        switch self {
        case .notInitialized:
            return "Database is not initialized"
        case .migrationFailed(let underlying):
            return "Database migration failed: \(underlying)"
        case .executionFailed(let underlying):
            return "Database execution failed: \(underlying)"
        }
    }
}

/// 迁移定义
public struct Migration {
    public let version: Int
    public let name: String
    public let apply: (Connection) throws -> Void

    public init(version: Int, name: String, apply: @escaping (Connection) throws -> Void) {
        self.version = version
        self.name = name
        self.apply = apply
    }
}

/// SQLite.swift 封装管理器
public final class DatabaseManager {
    public static let shared = DatabaseManager()

    private let queue = DispatchQueue(label: "com.perfectkitchen.db.queue")
    private var connection: Connection?
    private var migrations: [Migration] = []

    private init() {}

    // MARK: - Setup

    /// 初始化数据库（如首次启动时调用）
    public func setup(databaseFileName: String = "perfect_kitchen.sqlite3") throws {
        let dbURL = try Self.databaseURL(fileName: databaseFileName)

        // 创建连接
        let conn = try Connection(dbURL.path)
        conn.busyTimeout = 3.0
        conn.busyHandler { _ in true }
#if DEBUG
        conn.trace { print("[SQLite] \($0)") }
#endif

        // 设置后再赋值，避免中途被使用
        self.connection = conn

        // 确保迁移表存在
        try self.createMigrationsTableIfNeeded(using: conn)

        // 注册内置基础迁移（示例，可按需扩展或替换）
        registerBuiltInMigrations()

        // 执行迁移
        try performMigrationsIfNeeded(using: conn)
    }

    /// 数据库文件路径（Application Support/PerfectKitchen）
    private static func databaseURL(fileName: String) throws -> URL {
        let fm = FileManager.default
        let baseURL = try fm.url(for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)
        let appFolder = baseURL.appendingPathComponent("PerfectKitchen", isDirectory: true)
        if !fm.fileExists(atPath: appFolder.path) {
            try fm.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        return appFolder.appendingPathComponent(fileName, isDirectory: false)
    }

    // MARK: - Public API

    /// 只读操作（线程安全）
    public func read<T>(_ block: (Connection) throws -> T) throws -> T {
        try queue.sync {
            guard let conn = self.connection else { throw DatabaseError.notInitialized }
            do {
                return try block(conn)
            } catch {
                throw DatabaseError.executionFailed(underlying: error)
            }
        }
    }

    /// 写操作（线程安全，barrier）
    public func write<T>(_ block: (Connection) throws -> T) throws -> T {
        try queue.sync(flags: .barrier) {
            guard let conn = self.connection else { throw DatabaseError.notInitialized }
            do {
                return try block(conn)
            } catch {
                throw DatabaseError.executionFailed(underlying: error)
            }
        }
    }

    /// 事务写操作
    public func writeTransaction<T>(_ block: (Connection) throws -> T) throws -> T {
        try write { conn in
            var result: T!
            try conn.transaction {
                result = try block(conn)
            }
            return result
        }
    }

    // MARK: - Migration

    /// 注册迁移
    public func register(_ migration: Migration) {
        migrations.append(migration)
        migrations.sort { $0.version < $1.version }
    }

    private func registerBuiltInMigrations() {
        // 示例：创建一个简单的 recipes 表
        register(Migration(version: 1, name: "Create recipes table") { conn in
            let recipes = Table("recipes")
            let id = Expression<Int64>("id")
            let name = Expression<String>("name")
            let cuisine = Expression<String?>("cuisine")
            let createdAt = Expression<Date>("created_at")

            try conn.run(recipes.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(name, notNull: true)
                t.column(cuisine)
                t.column(createdAt, notNull: true)
            })
        })
    }

    private func createMigrationsTableIfNeeded(using conn: Connection) throws {
        let migrations = Table("schema_migrations")
        let version = Expression<Int>("version")
        let name = Expression<String>("name")
        let appliedAt = Expression<Date>("applied_at")

        try conn.run(migrations.create(ifNotExists: true) { t in
            t.column(version, primaryKey: true)
            t.column(name, notNull: true)
            t.column(appliedAt, notNull: true)
        })
    }

    private func currentMigrationVersions(using conn: Connection) throws -> Set<Int> {
        let migrationsTable = Table("schema_migrations")
        let version = Expression<Int>("version")
        var versions: Set<Int> = []
        for row in try conn.prepare(migrationsTable.select(version)) {
            versions.insert(row[version])
        }
        return versions
    }

    private func performMigrationsIfNeeded(using conn: Connection) throws {
        do {
            let applied = try currentMigrationVersions(using: conn)
            let toApply = migrations.filter { !applied.contains($0.version) }.sorted { $0.version < $1.version }
            guard !toApply.isEmpty else { return }

            try conn.transaction {
                let migrationsTable = Table("schema_migrations")
                let versionExp = Expression<Int>("version")
                let nameExp = Expression<String>("name")
                let appliedAtExp = Expression<Date>("applied_at")

                for m in toApply {
                    try m.apply(conn)
                    try conn.run(migrationsTable.insert(
                        versionExp <- m.version,
                        nameExp <- m.name,
                        appliedAtExp <- Date()
                    ))
                }
            }
        } catch {
            throw DatabaseError.migrationFailed(underlying: error)
        }
    }
}