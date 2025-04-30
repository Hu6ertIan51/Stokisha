//
//  GoalViewController.swift
//  Stokisha
//
//  Created by Ian Omondi on 08/04/2025.
//

import UIKit

class GoalViewController: UIViewController {
    
    private let separatorLine = UIView()

    @IBOutlet weak var submitbutton: UIButton!
    
    @IBOutlet weak var insertGoal: UITextField!
    
    @IBOutlet weak var submitGoal: UIButton!
    
    @IBOutlet weak var goalValue: UITextField!
    
    @IBOutlet weak var timeRemaining: UILabel!
    
    private var countdownTimer: Timer?
    
    private var timeRemainingUntilMidnight: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitGoal.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
        
        title = "GOAL 📈"
        checkBackendConnection()
        fetchCurrentGoal()
        presentHalfScreen()
        setupSeparatorLine()
        makeRounded()
        calculateTimeUntilMidnight()

        // Do any additional setup after loading the view.
    }
    
    private func calculateTimeUntilMidnight() {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        timeRemainingUntilMidnight = midnight.timeIntervalSince(now)
        
        updateTimeRemainingLabel()
        startCountdownTimer()
    }
    
    private func startCountdownTimer() {
        countdownTimer?.invalidate() // Cancel previous timer if exists
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.timeRemainingUntilMidnight -= 1
            
            if self.timeRemainingUntilMidnight <= 0 {
                self.countdownTimer?.invalidate()
                self.timeRemainingUntilMidnight = 0
                self.fetchCurrentGoal() // Refresh goal when day changes
            }
            
            self.updateTimeRemainingLabel()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdownTimer?.invalidate()
    }

    private func updateTimeRemainingLabel() {
        let hours = Int(timeRemainingUntilMidnight) / 3600
        let minutes = (Int(timeRemainingUntilMidnight) % 3600) / 60
        let seconds = Int(timeRemainingUntilMidnight) % 60
        
        DispatchQueue.main.async { [weak self] in
            self?.timeRemaining.text = String(format: "Time Remaining: %02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    private func checkBackendConnection() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/test-connection") else {
            print(" Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Connection failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    print("Connected to goal page: \(message)")
                } else {
                    print("Failed to parse response.")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
        
    private func fetchCurrentGoal() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/goals") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching goal:", error.localizedDescription)
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // First try to parse as JSON
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let goalDict = json["goal"] as? [String: Any],
                       let target = goalDict["target"] as? NSNumber {
                        // We have a goal
                        DispatchQueue.main.async {
                            self?.goalValue.text = "\(target.intValue)"
                            self?.submitGoal.isEnabled = false
                            self?.submitGoal.setTitle("Goal Set for Today", for: .disabled)
                            self?.submitGoal.backgroundColor = .lightGray
                        }
                    } else if json["message"] as? String == "No goal set for today" {
                        // No goal exists - this is normal
                        print("No goal set for today")
                    }
                }
            } catch {
                // If JSON parsing fails, try to read as plain text
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Received plain text response:", responseString)
                } else {
                    print("JSON parsing error:", error.localizedDescription)
                }
            }
        }
        task.resume()
    }
        
        @objc private func submitButtonTapped(_ sender: UIButton) {
            guard let goalText = goalValue.text,
                  let goalQuantity = Int(goalText) else {
                showAlert(title: "Error", message: "Please enter a valid number")
                return
            }
            
            sendGoalToAPI(goalQuantity: goalQuantity) { [weak self] success, errorMessage in
                DispatchQueue.main.async {
                    if success {
                        self?.showSuccessAlert()
                        self?.goalValue.text = ""
                        self?.submitGoal.isEnabled = false
                        self?.submitGoal.setTitle("Goal Set for Today", for: .disabled)
                        self?.submitGoal.backgroundColor = .lightGray
                    } else {
                        if let message = errorMessage, message.contains("GOAL_EXISTS") {
                            self?.showAlert(title: "Notice", message: "A goal already exists for today")
                            self?.fetchCurrentGoal()  // Fetch and display the existing goal
                        } else {
                            self?.showAlert(title: "Error", message: errorMessage ?? "Failed to save goal")
                        }
                    }
                }
            }
        }
        
        private func sendGoalToAPI(goalQuantity: Int, completion: @escaping (Bool, String?) -> Void) {
            guard let url = URL(string: "http://127.0.0.1:5000/api/goals") else {
                completion(false, "Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = ["goal_quantity": goalQuantity]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(false, "Invalid response")
                        return
                    }
                    
                    if httpResponse.statusCode == 201 {
                        completion(true, nil)
                    } else if let data = data,
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let errorMessage = json["error"] as? String {
                        completion(false, errorMessage)
                    } else {
                        completion(false, "Failed to save goal")
                    }
                }
                task.resume()
            } catch {
                completion(false, error.localizedDescription)
            }
        }

        
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else {
                print("View not in window hierarchy - can't present alert")
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func showSuccessAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else {
                print("View not in window hierarchy - can't present alert")
                return
            }
            
            let alert = UIAlertController(
                title: "Success ✅",
                message: "Goal saved successfully!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    //Make button rounded
    func makeRounded() {
        // Smooth rounded corners (not pill-shaped)
        submitbutton.layer.cornerRadius = 10  // Adjust for desired roundness
            
            // Shadow settings
        submitbutton.layer.shadowColor = UIColor.black.cgColor  // Shadow color
        submitbutton.layer.shadowOffset = CGSize(width: 0, height: 2)  // Shadow direction (downward)
        submitbutton.layer.shadowRadius = 4  // Shadow blur
        submitbutton.layer.shadowOpacity = 0.2  // Shadow transparency (0 to 1)
            
            // Important: Disable masksToBounds to allow shadow visibility
        submitbutton.layer.masksToBounds = false
            
            // Optional: Improve performance by defining shadow path
        submitbutton.layer.shadowPath = UIBezierPath(
                roundedRect: submitbutton.bounds,
                cornerRadius: submitbutton.layer.cornerRadius
            ).cgPath
        }

    func presentHalfScreen() {
        if let sheet = sheetPresentationController {
            // Create custom detent with your desired ratio (e.g., 0.4 for 40% of screen)
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("custom")) { context in
                // Return the height as a fraction of the maximum available height
                return context.maximumDetentValue * 0.3 // Adjust 0.4 to your preferred ratio (0.3-0.5)
            }
            
            sheet.detents = [customDetent] // Use only your custom detent
            sheet.prefersGrabberVisible = true
            
            // Optional: Prevent dismissing by dragging down
            sheet.largestUndimmedDetentIdentifier = .medium
        }
    }
    
    func setupSeparatorLine() {
        separatorLine.backgroundColor = UIColor.lightGray
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
}
