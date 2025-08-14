import Foundation
import SQLite

// MARK: - 数据库错误类型
/// 数据库相关错误，用于统一错误处理和打印日志
public enum DatabaseError: Error, CustomStringConvertible {
    /// 数据库还没初始化就被调用
    case notInitialized
    /// 数据库迁移失败（包括创建表、修改字段等）
    case migrationFailed(underlying: Error)
    /// 普通 SQL 执行失败
    case executionFailed(underlying: Error)

    /// 打印更友好的错误信息
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

// MARK: - 数据库迁移结构体
/// 描述一次数据库升级（迁移）的结构
/// - version: 迁移版本号，必须递增（例如 1, 2, 3）
/// - name: 描述信息，方便调试和记录
/// - apply: 迁移执行逻辑（在这里写建表、加字段、数据调整等）
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

// MARK: - 数据库管理器（单例）
/// 封装 SQLite.swift，支持线程安全和自动迁移
public final class DatabaseManager {
    /// 全局单例
    public static let shared = DatabaseManager()

    /// 串行队列，确保数据库线程安全
    private let queue = DispatchQueue(label: "com.perfectkitchen.db.queue")
    /// SQLite 数据库连接对象
    private var connection: Connection?
    /// 所有已注册的迁移（按 version 排序执行）
    private var migrations: [Migration] = []

    private init() {}

    // MARK: - 数据库初始化

    /// 初始化数据库（App 启动时调用）
    /// - databaseFileName: 数据库文件名，默认 "perfect_kitchen.sqlite3"
    /// - 会自动：
    ///   1. 创建数据库文件夹（在 Application Support 目录下）
    ///   2. 创建 SQLite 连接
    ///   3. 创建迁移记录表
    ///   4. 注册基础迁移（建表等）
    ///   5. 执行未完成的迁移
    public func setup(databaseFileName: String = "perfect_kitchen.sqlite3") throws {
        let dbURL = try Self.databaseURL(fileName: databaseFileName)

        // 创建连接
        let conn = try Connection(dbURL.path)
        conn.busyTimeout = 3.0
        conn.busyHandler { _ in true } // 如果被占用则重试
#if DEBUG
        conn.trace { print("[SQLite] \($0)") } // DEBUG 下打印所有 SQL
#endif

        // 设置后再赋值，避免未完全初始化就被使用
        self.connection = conn

        // 创建迁移记录表
        try self.createMigrationsTableIfNeeded(using: conn)

        // 注册内置的表结构迁移
        registerBuiltInMigrations()

        // 执行迁移
        try performMigrationsIfNeeded(using: conn)
    }

    /// 生成数据库文件路径（AppSupport/PerfectKitchen/xxx.sqlite3）
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

    // MARK: - 公共 API（线程安全读写）

    /// 执行只读操作
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

    /// 执行写操作（barrier 确保独占访问）
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

    /// 执行事务写操作（多个 SQL 一次性提交）
    public func writeTransaction<T>(_ block: (Connection) throws -> T) throws -> T {
        try write { conn in
            var result: T!
            try conn.transaction {
                result = try block(conn)
            }
            return result
        }
    }

    // MARK: - 迁移注册与执行

    /// 注册一个迁移（需要在 setup 之前调用）
    public func register(_ migration: Migration) {
        migrations.append(migration)
        migrations.sort { $0.version < $1.version }
    }

    /// 注册默认迁移（示例：创建 recipes 表）
    private func registerBuiltInMigrations() {
        register(Migration(version: 1, name: "Create recipes table") { conn in
            let recipes = Table("recipes")
            let id = Expression<Int64>("id")
            let name = Expression<String>("name")
            let cuisine = Expression<String?>("cuisine")
            let createdAt = Expression<Date>("created_at")

            try conn.run(recipes.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement) // 自增 ID
                t.column(name)
                t.column(cuisine)
                t.column(createdAt)
            })
        })
    }

    /// 创建迁移记录表（记录已执行的版本）
    private func createMigrationsTableIfNeeded(using conn: Connection) throws {
        let migrations = Table("schema_migrations")
        let version = Expression<Int>("version")
        let name = Expression<String>("name")
        let appliedAt = Expression<Date>("applied_at")

        try conn.run(migrations.create(ifNotExists: true) { t in
            t.column(version, primaryKey: true)
            t.column(name)
            t.column(appliedAt)
        })
    }

    /// 获取当前数据库已应用的迁移版本号
    private func currentMigrationVersions(using conn: Connection) throws -> Set<Int> {
        let migrationsTable = Table("schema_migrations")
        let version = Expression<Int>("version")
        var versions: Set<Int> = []
        for row in try conn.prepare(migrationsTable.select(version)) {
            versions.insert(row[version])
        }
        return versions
    }

    /// 执行所有未应用的迁移
    private func performMigrationsIfNeeded(using conn: Connection) throws {
        do {
            // 找出未执行的迁移
            let applied = try currentMigrationVersions(using: conn)
            let toApply = migrations.filter { !applied.contains($0.version) }.sorted { $0.version < $1.version }
            guard !toApply.isEmpty else { return }

            // 用事务保证迁移的原子性
            try conn.transaction {
                let migrationsTable = Table("schema_migrations")
                let versionExp = Expression<Int>("version")
                let nameExp = Expression<String>("name")
                let appliedAtExp = Expression<Date>("applied_at")

                for m in toApply {
                    try m.apply(conn) // 执行迁移逻辑
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

