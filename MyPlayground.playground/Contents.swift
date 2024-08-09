import UIKit

/// Результаты игр
private var quizResults: QuizResultsHistory?

/// Созраняет результаты игры
private func storeQuizResult() {
    if quizResults == nil {
        quizResults = QuizResultsHistory(
            questionsCount: quiz.questionsCount,
            results: []
        )
    }
    
    quizResults?.addResult(correctAnswersCount: quiz.correctAnswersCount)
}

/// История игр
fileprivate struct QuizResultsHistory {
    /// Колдичество вопросов (в каждой игре)
    let questionsCount: Int
    /// Результаты прошедших игр
    var results: [QuizResultHistory]
    
    /// Добавляет результат очередной игры
    mutating func addResult(correctAnswersCount: Int) {
        let result = QuizResultHistory(
            correctAnswersCount: correctAnswersCount,
            endDateTime: Date()
        )
        
        results.append(result)
    }
    
    /// Средняя точность ответов прошедших игр
    func averageAccuracy() -> Double {
        guard questionsCount > 0 else { return 0.0 }
        
        let totalCorrectAnswers = results.reduce(0.0) { prev, next in
                prev + Double(next.correctAnswersCount)
            }
        
        return totalCorrectAnswers / Double(questionsCount)
    }
}

/// Результат оконченной игры для истории
fileprivate struct QuizResultHistory {
    /// Количество правильных ответов
    let correctAnswersCount: Int
    /// Дата окончания игры
    let endDateTime: Date
    
    /// Точность ответов
    func accuracy(questionsCount: Int) -> Double {
        guard questionsCount > 0 else { return 0.0 }
        
        return Double(correctAnswersCount) / Double(questionsCount)
    }
}
