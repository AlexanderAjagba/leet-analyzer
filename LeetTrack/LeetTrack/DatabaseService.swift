import Foundation
import MongoSwift
import NIO

struct DatabaseConfig {
    static var mongoCom nnectionString: String {
        guard let connectionString = ProcessInfo.processInfo.environment["MONGO_CONNECTION_STRING"] else {
            fatalError("MONGO_CONNECTION_STRING environment variable not set")
        }
        return connectionString
    }
}

let elg = MultiThreadedEventLoopGroup(numberOfThreads: 4)
let client = try MongoClient(
    DatabaseConfig.mongoConnectionString,
    using: elg
)

defer {
    try? client.syncClose()
    cleanupMongoSwift()
    try? elg.syncShutdownGracefully()
}

print(try client.listDatabaseNames().wait())
