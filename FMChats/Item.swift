//
//  Item.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import Foundation
import SwiftData

@Model
final class Chat {
    var title: String = ""
    var timestamp: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var questions: [Question]? = []
    
    init(title: String, timestamp: Date = Date()) {
        self.title = title
        self.timestamp = timestamp
    }
}

@Model
final class Question {
    var questionText: String = ""
    var answerText: String?
    var timestamp: Date = Date()
    
    @Relationship(inverse: \Chat.questions)
    var chat: Chat?
    
    init(questionText: String, timestamp: Date = Date()) {
        self.questionText = questionText
        self.timestamp = timestamp
    }
}
