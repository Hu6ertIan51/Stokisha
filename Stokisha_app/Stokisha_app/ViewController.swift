
//
//  ViewController.swift
//  Stokisha
//
//  Created by Ian Omondi on 05/03/2025.
//

import UIKit

protocol InboundDelegate: AnyObject {
    func didAddNewInbound(withMessage message: String)  // Now accepts a parameter
}

struct SaleItem {
    let productName: String
    let quantitySold: Double
    let metric: String
    let saleDate: String?  // Add this property
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct StockItem {
        let productName: String
        let quantity: Double
        let createdAt: String?
    }
    
    @IBOutlet weak var redView: UIView!
    
    @IBOutlet weak var blueView: UIView!
    
    @IBOutlet weak var greenView: UIView!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var recentsLabel: UILabel!
    
    @IBOutlet weak var inboundsLabel: UILabel!
    
    @IBOutlet weak var salesLabel: UILabel!
    
    @IBOutlet weak var stackViewOutlet: UIStackView!
    
    @IBOutlet weak var recentInboundsTableView: UITableView!
    
    @IBOutlet weak var recentSalesTableView: UITableView!
    
    @IBOutlet weak var currentInbound: UILabel!
    
    @IBOutlet weak var currentSales: UILabel!
    
    @IBOutlet weak var dailyGoal: UILabel!
    
    var inbounds: [StockItem] = []
    
    var sales: [SaleItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBar()
        
        setupCornerRadius()
        
        setupStackViewConstraints()
        
        checkBackendConnection()
        
        updateGreeting()
        
        setupCardForTabBar()
        
        setupCardForStackView()
        
        
        //Set up tables
        setupInboundTable()
        setupSalesTable()
        
        fetchRecentInbounds()
        fetchRecentSales()
        fetchTotalInbounds()
        fetchTotalSales()
        fetchTodayGoal()
        fetchSales()
        
        // tap gesture to refresh data
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        
    }
    
    private func fetchSales() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/current-sales") else {
            salesLabel.text = "Invalid URL"
            print("Invalid URl")
            return
        }
        
        print("Attempting to fetch from:", url.absoluteString) // Debugging
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // Default values
            var sales = 0
            var displayText = "Error fetching sales"
            
            // Check for network errors first
            if let error = error {
                displayText = "Network error: \(error.localizedDescription)"
                print("Network error:", error.localizedDescription)
            }
            // Check for valid HTTP response
            else if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status:", httpResponse.statusCode)
                
                if httpResponse.statusCode == 200, let data = data {
                    // Debug raw response
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("Raw response:", rawString)
                    }
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        
                        if let salesValue = json?["sales"] as? Int {
                            sales = salesValue
                            displayText = "\(sales)"
                        } else {
                            displayText = "Invalid data format"
                            print("Invalid data format")
                            print("Couldn't find 'sales' key or wrong type in:", json ?? "nil")
                        }
                    } catch {
                        displayText = "Data parsing error"
                        print("JSON parsing error:", error)
                    }
                } else {
                    displayText = "Server error (\(httpResponse.statusCode))"
                }
            }
            
            DispatchQueue.main.async {
                self?.salesLabel.text = displayText
            }
        }.resume()
    }
    
    private func fetchTodayGoal() {
        let url = URL(string: "http://127.0.0.1:5000/api/today-goal")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // Default values
            var goal = 0
            var displayText = "No goal set today"
            
            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Safely handle goal value
                        if let goalValue = json["goal"] as? Int {
                            goal = goalValue
                        } else if let goalString = json["goal"] as? String,
                                  let goalValue = Int(goalString) {
                            goal = goalValue
                        } else if let goalDouble = json["goal"] as? Double {
                            goal = Int(goalDouble)
                        }
                        
                        displayText = goal > 0 ? "\(goal)" : "No goal set today"
                    }
                } catch {
                    displayText = "Error parsing data"
                    print("JSON error:", error)
                }
            } else {
                displayText = "Connection error"
                if let error = error {
                    print("Network error:", error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self?.dailyGoal.text = displayText
            }
        }.resume()
    }
    
    private func fetchTotalSales() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/total-sales") else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.currentSales.text = "Error"
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching total sales:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.currentSales.text = "Error"
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.currentSales.text = "No Data"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let total = json["total_sales"] as? Double {
                    DispatchQueue.main.async {
                        // Format as whole number if no decimals
                        let formattedTotal = total.truncatingRemainder(dividingBy: 1) == 0 ?
                            String(format: "%.0f", total) :
                            String(total)
                        
                        self.currentSales.text = formattedTotal
                        
                        // Optional animation like your inbound label
                        UIView.animate(withDuration: 0.3, animations: {
                            self.currentSales.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        }, completion: { _ in
                            UIView.animate(withDuration: 0.3) {
                                self.currentSales.transform = .identity
                            }
                        })
                    }
                }
            } catch {
                print("JSON error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.currentSales.text = "Error"
                }
            }
        }
        task.resume()
    }
    
    private func fetchRecentSales() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/recent-sales") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching sales:", error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code:", httpResponse.statusCode)
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            print("Raw Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                print("Received \(jsonArray.count) sales records")
                
                self.sales = jsonArray.compactMap { item in
                    guard let productName = item["product_name"] as? String,
                          let metric = item["metric"] as? String else {
                        print("Invalid record format - missing required fields:", item)
                        return nil
                    }
                    
                    // Handle quantity_sold which might be String, Double, or null
                    let quantitySold: Double
                    if let stringValue = item["quantity_sold"] as? String {
                        quantitySold = Double(stringValue) ?? 0
                    } else if let doubleValue = item["quantity_sold"] as? Double {
                        quantitySold = doubleValue
                    } else {
                        print("Invalid quantity_sold format, defaulting to 0:", item["quantity_sold"] ?? "nil")
                        quantitySold = 0
                    }
                    
                    let saleDate = item["sale_date"] as? String
                    return SaleItem(productName: productName,
                                  quantitySold: quantitySold,
                                  metric: metric,
                                  saleDate: saleDate)
                }
                
                print("Successfully parsed \(self.sales.count) items")
                
                DispatchQueue.main.async {
                    self.recentSalesTableView.reloadData()
                }
            } catch {
                print("JSON error:", error.localizedDescription)
            }
        }
        task.resume()
    }
    
    //Tap gestures
    @objc func handleTap() {
        fetchRecentInbounds()
        fetchRecentSales()
        fetchTotalInbounds()
        fetchTotalSales()
        fetchSales()
    }
    
    private func fetchTotalInbounds() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/total-inbounds") else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.currentInbound.text = "Error"
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching total inbounds: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.currentInbound.text = "Error"
                }
                return
            }
            
            guard let data = data else {
                print("No data received for total inbounds")
                DispatchQueue.main.async {
                    self.currentInbound.text = "No Data"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let total = json["total_inbounds"] as? Int {
                    DispatchQueue.main.async {
                        self.currentInbound.text = "\(total)"
                        // Optional: Add a brief animation to show the update
                        UIView.animate(withDuration: 0.3, animations: {
                            self.currentInbound.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        }, completion: { _ in
                            UIView.animate(withDuration: 0.3) {
                                self.currentInbound.transform = .identity
                            }
                        })
                    }
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.currentInbound.text = "Error"
                }
            }
        }
        task.resume()
    }
    
    func addNewInbound(productName: String, quantity: Double, createdAt: String) {
        let newInbound = StockItem(productName: productName, quantity: quantity,createdAt: createdAt )
        inbounds.insert(newInbound, at: 0) // Add the new inbound at the top
        
        // Insert a new row at the top of the table view
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.recentInboundsTableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    func addNewSale(productName: String, quantitySold: Int, metric: String, saleDate: String) {
        let newSale = SaleItem(productName: productName,
                              quantitySold: Double(quantitySold),
                               metric: metric, saleDate: saleDate)
        sales.insert(newSale, at: 0)
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.recentSalesTableView.insertRows(at: [indexPath], with: .automatic)
            self.fetchTotalSales() // Refresh the sales total after adding
        }
    }
    
    func fetchRecentInbounds() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/recent-inbounds") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let fetchedData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                
                if let fetchedData = fetchedData {
                    self.inbounds = fetchedData.compactMap { item in
                        if let productName = item["product_name"] as? String,
                           let quantity = item["quantity"] as? Double,
                           let createdAt = item["created_at"] as? String {
                            return StockItem(productName: productName,
                                           quantity: quantity,
                                           createdAt: createdAt)
                        }
                        return nil
                    }
                    
                    DispatchQueue.main.async {
                        self.recentInboundsTableView.reloadData()
                    }
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    
    private func setupInboundTable() {
        // Inbounds Table View setup
        recentInboundsTableView.dataSource = self
        recentInboundsTableView.delegate = self
        recentInboundsTableView.register(InboundTableViewCell.self, forCellReuseIdentifier: "InboundCell")
        recentInboundsTableView.separatorStyle = .none
        recentInboundsTableView.preservesSuperviewLayoutMargins = false
        recentInboundsTableView.layoutMargins = UIEdgeInsets.zero
        recentInboundsTableView.separatorInset = UIEdgeInsets.zero
    }
    
    private func setupSalesTable() {
        recentSalesTableView.dataSource = self
        recentSalesTableView.delegate = self
        
        // Critical settings
        recentSalesTableView.rowHeight = UITableView.automaticDimension
        recentSalesTableView.estimatedRowHeight = 68
        recentSalesTableView.register(SalesTableViewCell.self, forCellReuseIdentifier: "SalesCell")
        
        // Remove separators if desired
        recentSalesTableView.separatorStyle = .none
        
        // Ensure table view is visible
        recentSalesTableView.backgroundColor = .clear
        recentSalesTableView.isHidden = false
    }
    
    
    
    //Greetings logic
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting = "Good morning ☀️" // Default
        
        switch hour {
        case 6..<12:
            greeting = "Good morning ☀️"
        case 12..<17:
            greeting = "Good afternoon 🌤️"
        default:
            greeting = "Good evening 🌙"
        }
        
        welcomeLabel.text = greeting
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Fetch all the latest data
        fetchRecentInbounds()
        fetchRecentSales()
        fetchTotalInbounds()
        fetchTotalSales()
        fetchSales()
        fetchTodayGoal()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar again when leaving this page
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupTabBar() {
        guard let tabBarItems = self.tabBarController?.tabBar.items else { return }
        
        if tabBarItems.count > 0 {
            let homeTab = tabBarItems[0]  // First tab item
            homeTab.selectedImage = UIImage(systemName: "house.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
            homeTab.image = UIImage(systemName: "house")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        }
        
        tabBarController?.tabBar.tintColor = .black
        tabBarController?.tabBar.unselectedItemTintColor = .gray
    }
    
    private func setupCornerRadius() {
        [redView, blueView, greenView].forEach { view in
            view?.layer.cornerRadius = 15
            view?.clipsToBounds = true
        }
    }
    
    private func setupStackViewConstraints() {
        let stackView = UIStackView(arrangedSubviews: [redView, blueView, greenView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        
        view.addSubview(stackView) // Add to view
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            stackView.heightAnchor.constraint(equalToConstant: 120),
            
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    
    // Flask backend logic
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
                    print("Connected to backend: \(message)")
                } else {
                    print("Failed to parse response.")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    @IBAction func salesButtonTapped(_ sender: UIButton) {
        print("Sales button tapped")
        
        // Ensure stack view remains fixed
        UIView.animate(withDuration: 0.3) {
            self.stackViewOutlet.layoutIfNeeded()
        }
        
    }
    
    @IBAction func unwindToSummary(unwindSegue: UIStoryboardSegue) {
        if let sourceVC = unwindSegue.source as? AddNewInbound {
            // Show toast notification
            ToastNotification.show(message: "Inbound added successfully ✅",
                                   in: self.view)
            
            // Refresh data
            fetchRecentInbounds()
            fetchTotalInbounds()
            
            // Optional: If you need to access data from AddNewInbound
            // let addedProduct = sourceVC.productName.text
        }
    }
    
    //Tab bar card
    private func setupCardForTabBar() {
        guard let tabBar = self.tabBarController?.tabBar else { return }
        
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        tabBar.insertSubview(cardView, at: 0) // Send card to the back
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 40), // Increase to reduce width
            cardView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: -40), // Increase to reduce width
            cardView.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor, constant: -15),
            cardView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
    }
    
    private func setupCardForStackView() {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Insert the card view *behind* the stack view
        view.insertSubview(cardView, belowSubview: stackViewOutlet)
        
        // Disable auto constraints for stackViewOutlet
        stackViewOutlet.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Increase the width by adjusting the leading & trailing constraints
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // Reduce the inset
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), // Reduce the inset
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            cardView.heightAnchor.constraint(equalToConstant: 140),
            
            // Ensure stack view fits inside card
            stackViewOutlet.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            stackViewOutlet.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            stackViewOutlet.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            stackViewOutlet.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
        ])
        
        // Send other views to the front if needed
        view.bringSubviewToFront(stackViewOutlet)
        view.bringSubviewToFront(redView)
        view.bringSubviewToFront(blueView)
        view.bringSubviewToFront(greenView)
    }
    
    //Mark Table View Delegates
    //Number of rows defined in inbound
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == recentInboundsTableView {
            return inbounds.count
        } else if tableView == recentSalesTableView {
            return sales.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == recentInboundsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InboundCell", for: indexPath) as! InboundTableViewCell
            cell.configure(with: inbounds[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SalesCell", for: indexPath) as! SalesTableViewCell
            cell.configure(with: sales[indexPath.row])
            return cell
        }
    }
    
}

extension ViewController: InboundDelegate {
    func didAddNewInbound(withMessage message: String) {
        fetchRecentInbounds()
        fetchTotalInbounds()
        
        // Ensure the toast is added to the visible view hierarchy
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            ToastNotification.show(message: message, in: window)
        } else {
            ToastNotification.show(message: message, in: self.view)
        }
    }
}
