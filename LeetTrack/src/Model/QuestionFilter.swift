import Foundation

enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var apiValue: String { rawValue.uppercased() }
}

struct QuestionFilter {
    var difficulties: Set<Difficulty>

    static let all = QuestionFilter(difficulties: Set(Difficulty.allCases))
}


