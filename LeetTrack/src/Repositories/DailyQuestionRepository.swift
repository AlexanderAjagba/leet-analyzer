//
//  DailyQuestionRepository.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/27/25.
//

import Foundation
import MongoDBService
import MongoSwift

// Enhanced daily question with GMT date tracking
struct CachedDailyQuestion: Codable {
    let question: LeetCodeDailyQuestion
    let cachedAt: Date
    let gmtDate: String // Format: "YYYY-MM-DD" in GMT
    
    init(question: LeetCodeDailyQuestion) {
        self.question = question
        self.cachedAt = Date()
        
        let calendar = Calendar(identifier: .gregorian)
        var gmtCalendar = calendar
        gmtCalendar.timeZone = TimeZone(identifier: "GMT")!
        
        let year = gmtCalendar.component(.year, from: cachedAt)
        let month = gmtCalendar.component(.month, from: cachedAt)
        let day = gmtCalendar.component(.day, from: cachedAt)
        
        self.gmtDate = String(format: "%04d-%02d-%02d", year, month, day)
    }
}

public class DailyQuestionRepository {
    private let mongoService: MongoDBService
    private let collection: MongoCollection<BSONDocument>
    private let leetRepository: LeetCodeRepository = LeetCodeRepository()
    
    init(mongoService: MongoDBService) {
        self.mongoService = mongoService
        self.collection = mongoService.collection("daily_questions", in: "leettrack")
    }
    
    // Get daily question with MongoDB caching (global question, changes at midnight GMT)
    func getDailyQuestionWithRefresh() async throws -> LeetCodeDailyQuestion {
        let existing = try await getCachedDailyQuestion()
        let needsRefresh = existing == nil || isDataStale(existing!)
        
        if needsRefresh {
            let freshQuestion = try await leetRepository.getDailyQuestion()
            try await saveDailyQuestion(freshQuestion)
            return freshQuestion
        }
        
        return existing!.question
    }
    
    private func getCachedDailyQuestion() async throws -> CachedDailyQuestion? {
        let cursor = try await collection.find()
        for try await document in cursor {
            return try CachedDailyQuestion.fromBSONDocument(document)
        }
        return nil
    }
    
    private func saveDailyQuestion(_ question: LeetCodeDailyQuestion) async throws {
        // Clear existing and save new (only one daily question exists globally)
        try await collection.deleteMany([:])
        let cachedQuestion = CachedDailyQuestion(question: question)
        let document = try cachedQuestion.toBSONDocument()
        try await collection.insertOne(document)
    }
    
    // Check if daily question is stale (different GMT day)
    private func isDataStale(_ cachedQuestion: CachedDailyQuestion) -> Bool {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        var gmtCalendar = calendar
        gmtCalendar.timeZone = TimeZone(identifier: "GMT")!
        
        let year = gmtCalendar.component(.year, from: now)
        let month = gmtCalendar.component(.month, from: now)
        let day = gmtCalendar.component(.day, from: now)
        
        let currentGMTDate = String(format: "%04d-%02d-%02d", year, month, day)
        
        // Data is stale if it's from a different GMT day
        return cachedQuestion.gmtDate != currentGMTDate
    }
}

extension CachedDailyQuestion {
    func toBSONDocument() throws -> BSONDocument {
        let encoder = BSONEncoder()
        return try encoder.encode(self)
    }
    
    static func fromBSONDocument(_ doc: BSONDocument) throws -> CachedDailyQuestion {
        let decoder = BSONDecoder()
        return try decoder.decode(CachedDailyQuestion.self, from: doc)
    }
}

extension LeetCodeDailyQuestion {
    func toBSONDocument() throws -> BSONDocument {
        let encoder = BSONEncoder()
        return try encoder.encode(self)
    }
    
    static func fromBSONDocument(_ doc: BSONDocument) throws -> LeetCodeDailyQuestion {
        let decoder = BSONDecoder()
        return try decoder.decode(LeetCodeDailyQuestion.self, from: doc)
    }
}
