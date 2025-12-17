import Foundation

struct DailyQuestion: Codable, Equatable {
    let link: String
    let title: String
    let difficulty: String
    let date: String
}

struct DailyQuestionModel {
    var dailyQuestion: DailyQuestion?
    var isLoading: Bool = false
    var errorMessage: String?
}
