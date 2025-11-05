//
//  ProfileRepository.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/12/25.
//

import Foundation
import MongoDBService
import MongoSwift

public class ProfileRepository {
    private let mongoService: MongoDBService
    private let collection: MongoCollection<BSONDocument>
    private let leetRepository: LeetCodeRepository = LeetCodeRepository()
    
    init(mongoService: MongoDBService) {
        self.mongoService = mongoService
        self.collection = mongoService.collection("profiles", in: "leettrack")
    }
    
    // Save or update a profile in MongoDB
    func saveProfile(_ profile: Profile) async throws {
        let document = try profile.toBSONDocument()
        
        // Use upsert to either insert new or update existing
        let filter: BSONDocument = ["username": .string(profile.username)]
        let update: BSONDocument = ["$set": .document(document)]

        _ = try await collection.updateOne(
            filter: filter,
            update: update,
            options: UpdateOptions(upsert: true)
        )
    }
    
    // Get a profile by username from MongoDB
    func getProfile(username: String) async throws -> Profile? {
        let filter: BSONDocument = ["username": .string(username)]
        
        guard let document = try await collection.findOne(filter) else {
            return nil
        }
        
        return try Profile.fromBSONDocument(document)
    }
    
    // Get all profiles from MongoDB
    func getAllProfiles() async throws -> [Profile] {
        let cursor = try await collection.find()
        var profiles: [Profile] = []
        
        for try await document in cursor {
            let profile = try Profile.fromBSONDocument(document)
            profiles.append(profile)
        }
        
        return profiles
    }
    
    // Delete a profile by username
    func deleteProfile(username: String) async throws {
        let filter: BSONDocument = ["username": .string(username)]
        _ = try await collection.deleteOne(filter)
    }
    
    // Get profile with automatic refresh if data is stale (fetch stats via API, persist in Mongo)
    func getProfileWithRefresh(username: String) async throws -> Profile {
        let existing = try await getProfile(username: username)
        let needsNew = existing == nil || existing!.needsRefresh
        var profile = existing ?? Profile(username: username)
        if needsNew {
            let stats = try await leetRepository.getStats(username: username)
            profile.ranking = stats.ranking
            profile.easyQuestions = stats.easySolved
            profile.mediumQuestions = stats.mediumSolved
            profile.hardQuestions = stats.hardSolved
            profile.totalQuestions = stats.totalSolved
            profile.lastUpdated = Date()
            try await saveProfile(profile)
        }
        return profile
    }
    
    // Get recent activity (profiles updated in last 24 hours)
    func getRecentActivity() async throws -> [Profile] {
        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
        let filter: BSONDocument = [
            "lastUpdated": [
                "$gte": .datetime(yesterday)
            ]
        ]
        
        let cursor = try await collection.find(filter)
        var profiles: [Profile] = []
        
        for try await document in cursor {
            let profile = try Profile.fromBSONDocument(document)
            profiles.append(profile)
        }
        
        return profiles.sorted {
            ($0.lastUpdated ?? Date.distantPast) > ($1.lastUpdated ?? Date.distantPast)
        }
    }
}
