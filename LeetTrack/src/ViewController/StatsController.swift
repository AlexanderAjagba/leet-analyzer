//
//  StatsController.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import Foundation
import MongoDBService

class StatsController: ObservableObject {
    @Published var model = StatsModel()
    
    private let problemRepository: ProblemRepository
    
    init() {
        do {
            let mongoService = try MongoDBService()
            self.problemRepository = ProblemRepository(mongoService: mongoService)
        } catch {
            fatalError("Failed to initialize MongoDB service: \(error)")
        }
    }
    
    @MainActor
    func loadRecentProblems() async {
        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }
        
        do {
            // MongoDB-first approach: check Atlas first, fallback to API if needed
            let recentProblems = try await problemRepository.getRecentProblems()
            model.recentProblems = recentProblems
            model.lastUpdated = Date()
        } catch {
            model.errorMessage = "Failed to load recent problems: \(error.localizedDescription)"
            model.recentProblems = []
        }
    }
    
    // Force refresh from API (bypasses MongoDB cache)
    @MainActor
    func forceRefreshProblems() async {
        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }
        
        do {
            // Force fetch from API and save to MongoDB
            let repository = LeetCodeRepository()
            let freshProblems = try await repository.getProblems(difficulty: nil)
            try await problemRepository.saveProblems(freshProblems)
            model.recentProblems = Array(freshProblems.prefix(10))
            model.lastUpdated = Date()
        } catch {
            model.errorMessage = "Failed to refresh problems: \(error.localizedDescription)"
        }
    }
}
