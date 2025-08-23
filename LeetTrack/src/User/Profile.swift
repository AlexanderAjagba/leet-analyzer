//
//  Profile.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 7/9/25.
//

import Foundation
import MongoSwift

public struct Profile: Codable {
    var _id: BSONObjectID?
    var username: String
    var ranking: Int?
    var easyQuestions: Int?
    var mediumQuestions: Int?
    var hardQuestions: Int?
    var totalQuestions: Int?
    var lastUpdated: Date?
    
    // API response structure for LeetCode stats
    private struct LeetCodeResponse: Codable {
        let totalSolved: Int?
        let totalQuestions: Int?
        let easySolved: Int?
        let mediumSolved: Int?
        let hardSolved: Int?
        let ranking: Int?
    }
    
    init(username: String) {
        self.username = username
        self.lastUpdated = Date()
    }
    
    mutating func fetchData() async throws {
        guard let url = URL(string: "https://alfa-leetcode-api.onrender.com/\(username)") else {
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Parse the JSON response
            let leetcodeData = try JSONDecoder().decode(LeetCodeResponse.self, from: data)
            
            // Update profile properties
            self.ranking = leetcodeData.ranking
            self.easyQuestions = leetcodeData.easySolved
            self.mediumQuestions = leetcodeData.mediumSolved
            self.hardQuestions = leetcodeData.hardSolved
            self.totalQuestions = leetcodeData.totalSolved
            self.lastUpdated = Date()
            
        } catch {
            print("Error fetching LeetCode data for \(username): \(error)")
            throw error
        }
    }
    
    // Convert Profile to BSON Document for MongoDB storage
    func toBSONDocument() throws -> BSONDocument {
        let encoder = BSONEncoder()
        return try encoder.encode(self)
    }
    
    // Create Profile from BSON Document
    static func fromBSONDocument(_ doc: BSONDocument) throws -> Profile {
        let decoder = BSONDecoder()
        return try decoder.decode(Profile.self, from: doc)
    }
    
    // Check if data needs refresh (older than 1 hour)
    var needsRefresh: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 3600 // 1 hour
    }
    
    // Convenience method to get formatted stats
    var formattedStats: String {
        let total = totalQuestions ?? 0
        let easy = easyQuestions ?? 0
        let medium = mediumQuestions ?? 0
        let hard = hardQuestions ?? 0
        
        return "Total: \(total) | Easy: \(easy) | Medium: \(medium) | Hard: \(hard)"
    }
}
