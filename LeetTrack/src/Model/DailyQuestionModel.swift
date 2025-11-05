//
//  DailyQuestionModel.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import Foundation

struct DailyQuestionModel {
    var dailyQuestion: LeetCodeDailyQuestion?
    var isLoading: Bool = false
    var errorMessage: String?
}
