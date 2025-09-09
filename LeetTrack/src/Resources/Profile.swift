//
//  Profile.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 7/9/25.
//

import Foundation
import MongoSwift

class ProfileManager : ObservableObject {
    @Published var currentProfile = Profile(username: "")
    static var shared = ProfileManager()
}

public class Profile: Codable, ObservableObject {
    var _id: BSONObjectID?
    @Published var username: String
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
    
    func fetchData() async throws {
        guard let url = URL(string: "https://alfa-leetcode-api.onrender.com/\(ProfileManager.shared.currentProfile)") else {
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
    
    enum CodingKeys: String, CodingKey {
        case _id, username, ranking, easyQuestions, mediumQuestions, hardQuestions, totalQuestions, lastUpdated
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(BSONObjectID.self, forKey: ._id)
        self.username = try container.decode(String.self, forKey: .username)
        self.ranking = try container.decodeIfPresent(Int.self, forKey: .ranking)
        self.easyQuestions = try container.decodeIfPresent(Int.self, forKey: .easyQuestions)
        self.mediumQuestions = try container.decodeIfPresent(Int.self, forKey: .mediumQuestions)
        self.hardQuestions = try container.decodeIfPresent(Int.self, forKey: .hardQuestions)
        self.totalQuestions = try container.decodeIfPresent(Int.self, forKey: .totalQuestions)
        self.lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(_id, forKey: ._id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(ranking, forKey: .ranking)
        try container.encodeIfPresent(easyQuestions, forKey: .easyQuestions)
        try container.encodeIfPresent(mediumQuestions, forKey: .mediumQuestions)
        try container.encodeIfPresent(hardQuestions, forKey: .hardQuestions)
        try container.encodeIfPresent(totalQuestions, forKey: .totalQuestions)
        try container.encodeIfPresent(lastUpdated, forKey: .lastUpdated)
    }
}
