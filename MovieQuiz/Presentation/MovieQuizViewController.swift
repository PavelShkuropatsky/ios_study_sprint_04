import UIKit

final class MovieQuizViewController: UIViewController {
    
    /// Информация об игре
    private var quiz = Quiz()
    
    @IBOutlet private weak var quizProgressLabel: UILabel!
    @IBOutlet private weak var filmImage: UIImageView!
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showCurrentStep()
    }
    
    /// Выводит в интерфейс данные шага игры
    private func show(quizStep: QuizStepViewModel) {
        self.hideAnswerResultOnImage()
        
        quizProgressLabel.text = quizStep.quizProgress
        filmImage.image = quizStep.image
        questionLabel.text = quizStep.questionText
    }
    
    /// Выводит в интерфейс данные текущего шага игры
    private func showCurrentStep() { show(quizStep: quiz.currentStep) }
    
    /// Обрабатывает результат ответа
    /// - Parameter isCorrect: правилен ли ответ
    private func proceedAnswerResult(isCorrect: Bool) {
        isEnabledButtons(false)
        
        if isCorrect { quiz.correctAnswersCount += 1 }
        
        showAnswerResultOnImage(isCorrect: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
            
            self.isEnabledButtons(true)
        }
    }
    
    /// Изменяет доступность кнопок
    /// - недоступно - на время перехода между состояниями игры
    /// - доступно - после завершения перехода
    private func isEnabledButtons(_ value : Bool) {
        noButton.isEnabled = value
        yesButton.isEnabled = value
    }
    
    /// Отображает рамку вокруг постера фильма при получении ответа на вопрос
    private func showAnswerResultOnImage(isCorrect: Bool) {
        let borderColor = (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor
        
        filmImage.layer.borderWidth = 8
        filmImage.layer.borderColor = borderColor
    }
    
    /// Скрывает рамку вокруг постера фильма при переходе на следующий вопрос
    private func hideAnswerResultOnImage() {
        filmImage.layer.borderWidth = 0
        filmImage.layer.borderColor = nil
    }
    
    /// В зависимости от состояния игры:
    /// переходит к результатам, если игра завершена, иначе
    /// переходит к следующему вопросу
    private func showNextQuestionOrResults() {
        if quiz.isQuizOver() {
            showQuizResult()
        } else {
            quiz.shiftToNextStep()
            showCurrentStep()
        }
    }
    
    /// Отображает результаты игры
    private func showQuizResult() {
        let result = quiz.makeResultViewModel()
        
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(
            title: result.buttonText,
            style: .default
        ) { _ in
            self.quiz.reset()
            self.showCurrentStep()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    /// Нажатие кнопки "Нет"
    @IBAction private func noOnClicked() {
        proceedAnswerResult(isCorrect: quiz.currentAnswerIsCorrect(givenAnswer: false))
    }
    
    /// Нажатие кнопки "Да"
    @IBAction private func yesOnClicked() {
        proceedAnswerResult(isCorrect: quiz.currentAnswerIsCorrect(givenAnswer: true))
    }
}

/// Информация об игре
fileprivate struct Quiz {
    /// Вопросы
    let questions: [QuizQuestion]
    /// Количество вопросов
    let questionsCount: Int
    
    /// Количество правильных ответов внутри партии
    var correctAnswersCount: Int
    
    /// Номер текущего шага игры
    var currentStepNumber: Int
    /// Текущий шаг игры
    var currentStep: QuizStepViewModel
    
    /// Текущий вопрос
    var currentQuestion: QuizQuestion { questions[currentStepNumber] }
    
    ///// Прогресс игры в текстовом виде
    //var progressText: String { "\(currentStepNumber)/\(questionsCount)" }
    
    init() {
        self.questions = initialQuestions()
        self.questionsCount = questions.count
        self.correctAnswersCount = 0
        
        self.currentStepNumber = 0
        self.currentStep = QuizStepViewModel(
            currentStep: currentStepNumber,
            totalStep: questionsCount,
            question: questions[currentStepNumber])
    }
    
    /// Сдвигает игру на следующий шаг
    mutating func shiftToNextStep() {
        currentStepNumber += 1
        
        currentStep = QuizStepViewModel(
            currentStep: currentStepNumber,
            totalStep: questionsCount,
            question: questions[currentStepNumber])
    }
    
    /// Сбрасывает игру на начало
    mutating func reset() {
        correctAnswersCount = 0
        
        currentStepNumber = 0
        currentStep = QuizStepViewModel(
            currentStep: currentStepNumber,
            totalStep: questionsCount,
            question: questions[currentStepNumber])
    }
    
    /// Правилен ли ответ на текущий вопрос?
    /// - Parameter answer: ответ
    func currentAnswerIsCorrect(givenAnswer: Bool) -> Bool {
        currentQuestion.correctAnswer == givenAnswer
    }
    
    /// Имеются ли ещё вопросы?
    func hasMoreQuestions() -> Bool { questionsCount > currentStepNumber + 1 }
    
    /// Окончена ли игра?
    func isQuizOver() -> Bool { !hasMoreQuestions() }
    
    /// Создаёт объект с результатом игры для отображения пользователю
    func makeResultViewModel() -> QuizResultViewModel {
        QuizResultViewModel.success(
            text: "Ваш результат: \(correctAnswersCount)/\(questionsCount)"
        )
    }
}

/// Информация о шаге игры для отображения пользователю
private struct QuizStepViewModel {
    /// Постер фильма
    let image: UIImage
    
    /// Текст вопроса
    let questionText: String
    
    /// Прогресс игры
    let quizProgress: String
    
    init(
        currentStep: Int,
        totalStep: Int,
        question: QuizQuestion
    ) {
        self.image = UIImage(named: question.filmImage) ?? UIImage()
        self.questionText = question.text
        self.quizProgress = "\(currentStep + 1)/\(totalStep)"
    }
}

/// Данные о результате игры
private struct QuizResultViewModel {
    /// Заголовок сообщения о результатах
    let title: String
    
    /// Текст с результатом
    let text: String
    
    /// Текст для кнопки алерта
    let buttonText: String
    
    /// Конструктор для успешного завершения игры
    static func success(text: String) -> QuizResultViewModel {
        QuizResultViewModel(
            title: "Этот раунд окончен!",
            text: text,
            buttonText: "Сыграть ещё раз"
        )
    }
    
    /// Конструктор для сбойного завершения игры
    static func fail() -> QuizResultViewModel {
        QuizResultViewModel(
            title: "Что-то пошло не так(",
            text: "Невозможно загрузить данные",
            buttonText: "Попробовать ещё раз"
        )
    }
}

/// Данные о вопросе
private struct QuizQuestion {
    /// Название фильма
    let filmName: String
    
    /// Постер фильма (совпадает с названием фильма)
    var filmImage: String { filmName }
    
    /// Рейтинг фильма
    let filmRating: Double
    
    /// Текст вопроса
    let text: String
    
    /// Правильный ли получен ответ?
    let correctAnswer: Bool
}



/// Вопросы (мок-данные)
private func initialQuestions() -> [QuizQuestion] {
    [QuizQuestion(
        filmName: "The Godfather",
        filmRating: 9.2,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "The Dark Knight",
        filmRating: 9,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "Kill Bill",
        filmRating: 8.1,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "The Avengers",
        filmRating: 8,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "Deadpool",
        filmRating: 8,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "The Green Knight",
        filmRating: 6.6,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: true),
     
     QuizQuestion(
        filmName: "Old",
        filmRating: 5.8,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: false),
     
     
     QuizQuestion(
        filmName: "The Ice Age Adventures of Buck Wild",
        filmRating: 4.3,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: false),
     
     QuizQuestion(
        filmName: "Tesla",
        filmRating: 5.1,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: false),
     
     QuizQuestion(
        filmName: "Vivarium",
        filmRating: 5.8,
        text: "Рейтинг этого фильма больше чем 6?",
        correctAnswer: false)]
}

/*
 Mock-данные
 
 
 Картинка: The Godfather
 Настоящий рейтинг: 9,2
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Dark Knight
 Настоящий рейтинг: 9
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Kill Bill
 Настоящий рейтинг: 8,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Avengers
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Deadpool
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Green Knight
 Настоящий рейтинг: 6,6
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Old
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: The Ice Age Adventures of Buck Wild
 Настоящий рейтинг: 4,3
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Tesla
 Настоящий рейтинг: 5,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Vivarium
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 */
