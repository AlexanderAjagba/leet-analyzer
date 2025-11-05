//
//  HomeController.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import Foundation
import SwiftUI
import MongoDBService

@MainActor
class HomeController: ObservableObject {
    @Published var homeModel = HomeModel()
    
    private let mongoService: MongoDBService
    private let profileRepository: ProfileRepository
    
    init() {
        do {
            self.mongoService = try MongoDBService()
            self.profileRepository = ProfileRepository(mongoService: mongoService)
        } catch {
            fatalError("Failed to initialize MongoDB service: \(error)")
        }
        
        // Load recent activity on initialization
        Task {
            await loadRecentActivity()
        }
    }
    
    // Load profile data from MongoDB (with API fallback if needed)
    func loadUserProfile(username: String) {
        Task {
            homeModel.isLoading = true
            homeModel.errorMessage = nil
            
            do {
                let loadedProfile = try await profileRepository.getProfileWithRefresh(username: username)
                homeModel.profile = loadedProfile
                homeModel.isLoading = false
            } catch {
                homeModel.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                homeModel.isLoading = false
            }
        }
    }
    
    // Force refresh current profile data from API
    
    
    func forceRefreshProfile() {
        guard let currentUsername = homeModel.profile?.username else { return }
        
        Task {
            homeModel.isLoading = true
            homeModel.errorMessage = nil
            
            do {
                let repository = LeetCodeRepository()
                let stats = try await repository.getStats(username: currentUsername)
                var newProfile = Profile(username: currentUsername)
                newProfile.ranking = stats.ranking
                newProfile.easyQuestions = stats.easySolved
                newProfile.mediumQuestions = stats.mediumSolved
                newProfile.hardQuestions = stats.hardSolved
                newProfile.totalQuestions = stats.totalSolved
                newProfile.lastUpdated = Date()
                try await profileRepository.saveProfile(newProfile)
                
                homeModel.profile = newProfile
                homeModel.isLoading = false
            } catch {
                homeModel.errorMessage = "Failed to refresh profile: \(error.localizedDescription)"
                homeModel.isLoading = false
            }
        }
    }
    
    // Load recent activity from MongoDB
    private func loadRecentActivity() async {
        do {
            let recent = try await profileRepository.getRecentActivity()
            homeModel.recentProfiles = recent
        } catch {
            print("Failed to load recent activity: \(error)")
        }
    }
    
    // Load a profile from recent activity
    func loadRecentProfile(_ profile: Profile) {
        homeModel.profile = profile
    }
    
    // Clear current profile
    func clearProfile() {
        homeModel.profile = nil
        homeModel.errorMessage = nil
    }
    
    // Delete a profile from MongoDB
    func deleteProfile(username: String) {
        Task {
            do {
                try await profileRepository.deleteProfile(username: username)
                // Refresh recent activity
                await loadRecentActivity()
                
                // Clear current profile if it was the deleted one
                if homeModel.username == username {
                    clearProfile()
                }
            } catch {
                homeModel.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            }
        }
    }
    
    // Get all stored profiles
    func getAllProfiles() async -> [Profile] {
        do {
            return try await profileRepository.getAllProfiles()
        } catch {
            print("Failed to get all profiles: \(error)")
            return []
        }
    }
    
    // Check if we have valid profile data
    var hasValidProfile: Bool {
        homeModel.profile != nil && homeModel.errorMessage == nil
    }
    
    // Check if current profile needs refresh
    var profileNeedsRefresh: Bool {
        homeModel.profile?.needsRefresh ?? false
    }
    
    deinit {
        mongoService.shutdown()
    }
}
