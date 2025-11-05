import Foundation

enum AppConfig {
    static var leetCodeAPIBaseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "LEETCODE_API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "https://alfa-leetcode-api.onrender.com"
    }

    static var profileAPIBaseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "PROFILE_API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:3000"
    }
}


