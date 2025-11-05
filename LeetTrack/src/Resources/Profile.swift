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
    
    private let mongoService: MongoDBService
    private let profileRepository: ProfileRepository
    private let leetRepository = LeetCodeRepository()
    private var updateTimer: Timer?
    
    // Rate limiting
    private var lastAPICall: Date?
    private let minAPIIntersval: TimeInterval = 60 // Minimum 1 minute between API calls
    private var consecutiveFailures = 0
    private let maxFailures = 3
    
    init() {
        do {
            self.mongoService = try MongoDBService()
            self.profileRepository = ProfileRepository(mongoService: mongoService)
            startPeriodicUpdates()
        } catch {
            print("Failed to initialize MongoDB service: \(error)")
            self.mongoService = try! MongoDBService() // Fallback for compilation
            self.profileRepository = ProfileRepository(mongoService: self.mongoService)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
        mongoService.shutdown()
    }
    
    // Load username from MongoDB or create new profile
    func loadProfile(userId: String) async {
        do {
            if let profile = try await profileRepository.getProfile(username: userId) {
                await MainActor.run { self.currentProfile = profile }
            } else {
                await MainActor.run { self.currentProfile = Profile(username: userId) }
                await saveProfile()
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    // Save current profile to MongoDB
    func saveProfile() async {
        do {
            try await profileRepository.saveProfile(currentProfile)
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    // Update username and save to MongoDB
    func updateUsername(_ newUsername: String) async {
        await MainActor.run {
            self.currentProfile.username = newUsername
        }
        await saveProfile()
    }
    
    // Start periodic updates every 15 minutes (more conservative)
    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshLeetCodeStats()
            }
        }
    }
    
    // Refresh LeetCode stats with rate limiting and exponential backoff
    private func refreshLeetCodeStats() async {
        guard !currentProfile.username.isEmpty else { return }
        
        // Check rate limiting
        if let lastCall = lastAPICall {
            let timeSinceLastCall = Date().timeIntervalSince(lastCall)
            if timeSinceLastCall < minAPIIntersval {
                print("Rate limited: Skipping API call. Last call was \(Int(timeSinceLastCall))s ago")
                return
            }
        }
        
        // If we've had too many consecutive failures, back off
        if consecutiveFailures >= maxFailures {
            print("Too many consecutive failures (\(consecutiveFailures)). Skipping API call.")
            return
        }
        
        do {
            let stats = try await leetRepository.getStats(username: currentProfile.username)
            await MainActor.run {
                self.currentProfile.ranking = stats.ranking
                self.currentProfile.easyQuestions = stats.easySolved
                self.currentProfile.mediumQuestions = stats.mediumSolved
                self.currentProfile.hardQuestions = stats.hardSolved
                self.currentProfile.totalQuestions = stats.totalSolved
                self.currentProfile.lastUpdated = Date()
            }
            await saveProfile()
            
            // Reset failure count on success
            consecutiveFailures = 0
            lastAPICall = Date()
            
        } catch {
            consecutiveFailures += 1
            print("Failed to refresh LeetCode stats (attempt \(consecutiveFailures)/\(maxFailures)): \(error)")
            
            // If it's a rate limit error, increase the backoff
            if let urlError = error as? URLError, urlError.code == .tooManyRequests {
                print("Rate limit hit. Backing off for \(minAPIIntersval * 2) seconds")
                lastAPICall = Date().addingTimeInterval(-minAPIIntersval * 2)
            }
        }
    }
    
    // Manual refresh with rate limiting
    func manualRefresh() async {
        await refreshLeetCodeStats()
    }
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
