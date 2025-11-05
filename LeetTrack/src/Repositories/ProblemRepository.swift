//
//  ProblemRepository.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/27/25.
//

import Foundation
import MongoDBService
import MongoSwift

public class ProblemRepository {
    private let mongoService: MongoDBService
    private let collection: MongoCollection<BSONDocument>
    private let leetRepository: LeetCodeRepository = LeetCodeRepository()
    
    init(mongoService: MongoDBService) {
        self.mongoService = mongoService
        self.collection = mongoService.collection("problems", in: "leettrack")
    }
    
    // Save problems to MongoDB
    func saveProblems(_ problems: [LeetCodeProblem]) async throws {
        // Clear existing problems first
        try await collection.deleteMany([:])
        
        // Insert new problems
        let documents = try problems.map { problem in
            try problem.toBSONDocument()
        }
        
        if !documents.isEmpty {
            try await collection.insertMany(documents)
        }
    }
    
    // Get problems from MongoDB
    func getProblems() async throws -> [LeetCodeProblem] {
        let cursor = try await collection.find()
        var problems: [LeetCodeProblem] = []
        
        for try await document in cursor {
            let problem = try LeetCodeProblem.fromBSONDocument(document)
            problems.append(problem)
        }
        
        return problems
    }
    
    // Get problems with automatic refresh if data is stale (fetch from API, persist in Mongo)
    func getProblemsWithRefresh() async throws -> [LeetCodeProblem] {
        let existing = try await getProblems()
        let needsRefresh = existing.isEmpty || isDataStale(existing)
        
        if needsRefresh {
            // Fetch fresh data from LeetCode API
            let freshProblems = try await leetRepository.getProblems(difficulty: nil)
            try await saveProblems(freshProblems)
            return freshProblems
        }
        
        return existing
    }
    
    // Check if data is stale (older than 1 hour)
    private func isDataStale(_ problems: [LeetCodeProblem]) -> Bool {
        // For simplicity, we'll consider data stale if it's been more than 1 hour
        // In a real implementation, you might store a timestamp with the problems
        return true // Always refresh for now, can be improved with timestamps
    }
    
    // Get recent problems (first 10)
    func getRecentProblems() async throws -> [LeetCodeProblem] {
        let allProblems = try await getProblemsWithRefresh()
        return Array(allProblems.prefix(10))
    }
}

// Extension to make LeetCodeProblem work with BSON
extension LeetCodeProblem {
    func toBSONDocument() throws -> BSONDocument {
        let encoder = BSONEncoder()
        return try encoder.encode(self)
    }
    
    static func fromBSONDocument(_ doc: BSONDocument) throws -> LeetCodeProblem {
        let decoder = BSONDecoder()
        return try decoder.decode(LeetCodeProblem.self, from: doc)
    }
}
