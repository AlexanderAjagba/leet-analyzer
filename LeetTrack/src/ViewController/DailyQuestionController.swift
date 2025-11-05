//
//  DailyQuestionController.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import Foundation
import MongoDBService

class DailyQuestionController: ObservableObject {
    @Published var model = DailyQuestionModel()
    
    private let dailyQuestionRepository: DailyQuestionRepository
    
    init() {
        do {
            let mongoService = try MongoDBService()
            self.dailyQuestionRepository = DailyQuestionRepository(mongoService: mongoService)
        } catch {
            fatalError("Failed to initialize MongoDB service: \(error)")
        }
    }
    
    @MainActor
    func loadDailyQuestion() async {
        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }
        
        do {
            // MongoDB-first approach: check Atlas first, fallback to API if needed
            model.dailyQuestion = try await dailyQuestionRepository.getDailyQuestionWithRefresh()
        } catch {
            model.errorMessage = "Not available right now"
            model.dailyQuestion = nil
        }
    }
    
    // Force refresh from API (bypasses MongoDB cache)
    @MainActor
    func forceRefreshDailyQuestion() async {
        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }
        
        do {
            // Force fetch from API and save to MongoDB
            let repository = LeetCodeRepository()
            let freshQuestion = try await repository.getDailyQuestion()
            model.dailyQuestion = freshQuestion
            // Note: The repository will handle saving to MongoDB automatically
        } catch {
            model.errorMessage = "Failed to refresh daily question"
        }
    }
}