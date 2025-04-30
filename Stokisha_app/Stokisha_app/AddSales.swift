//
//  AddSales.swift
//  Stokisha
//
//  Created by Ian Omondi on 07/03/2025.
//

import UIKit

class AddSales: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var productName: UITextField!
    
    @IBOutlet weak var quantityRem: UITextField!
    
    private let separatorLine = UIView()
    
    @IBOutlet weak var quantitySold: UITextField!
    
    @IBOutlet weak var metric: UITextField!
    
    @IBOutlet weak var backgroundCard: UIView!
    
    @IBOutlet weak var buttonSales: UIButton!
    
    // MARK: - Properties
    private var productPicker = UIPickerView()
    private var quantityPicker = UIPickerView()
    private var metricPicker = UIPickerView()
    
    private var productList: [String] = []
    private var productDict: [String: Int] = [:]
    private var selectedProductId: Int?
    private let metrics = ["kg", "g", "l", "ml", "units"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        buttonSales.addTarget(self, action: #selector(submitSale(_:)), for: .touchUpInside)
        
        presentHalfScreen()
        setupSeparatorLine()
        borderedTextField()
        setupBackgroundCard()
        styleSalesButton()
        
        setupUI()
        setupPickers()
        fetchProducts()
        
    }
    // MARK: - Setup Methods
        private func setupUI() {
            presentHalfScreen()
            setupSeparatorLine()
            borderedTextField()
            setupBackgroundCard()
            styleSalesButton()
            
            // Configure remaining quantity field
            quantityRem.isUserInteractionEnabled = false
            quantityRem.backgroundColor = UIColor.systemGray6
        }
        
        private func setupPickers() {
            // Product Picker
            productPicker.delegate = self
            productPicker.dataSource = self
            productName.inputView = productPicker
            addToolbar(to: productName)
            
            // Quantity Picker (1-100)
            quantityPicker.delegate = self
            quantityPicker.dataSource = self
            quantityPicker.tag = 1
            quantitySold.inputView = quantityPicker
            addToolbar(to: quantitySold)
            quantitySold.text = "1" // Default value
            
            // Metric Picker
            metricPicker.delegate = self
            metricPicker.dataSource = self
            metricPicker.tag = 2
            metric.inputView = metricPicker
            addToolbar(to: metric)
        }
        
        private func addToolbar(to textField: UITextField) {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissKeyboard))
            toolbar.setItems([doneButton], animated: true)
            textField.inputAccessoryView = toolbar
        }
        
        @objc private func dismissKeyboard() {
            view.endEditing(true)
        }
        
        // MARK: - Data Fetching
        private func fetchProducts() {
            guard let url = URL(string: "http://127.0.0.1:5000/api/fetch-products") else {
                print("Invalid URL")
                return
            }

            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching products: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let productDict = try JSONDecoder().decode([String: Int].self, from: data)
                    DispatchQueue.main.async {
                        self.productList = Array(productDict.keys).sorted()
                        self.productDict = productDict
                        self.productPicker.reloadAllComponents()
                        
                        // Select first product by default if available
                        if !self.productList.isEmpty {
                            let firstProduct = self.productList[0]
                            self.productName.text = firstProduct
                            self.selectedProductId = productDict[firstProduct]
                            self.fetchRemainingQuantity(for: self.selectedProductId)
                        }
                    }
                } catch {
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
        
        private func fetchRemainingQuantity(for productId: Int?) {
            guard let productId = productId else { return }
            
            guard let url = URL(string: "http://127.0.0.1:5000/api/product-stock/\(productId)") else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching stock: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data else {
                    print("Invalid response")
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(ProductStockResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.quantityRem.text = "\(result.remaining_quantity)"
                    }
                } catch {
                    print("Decoding error: \(error.localizedDescription)")
                }
            }.resume()
        }
        
        // MARK: - PickerView DataSource & Delegate
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch pickerView {
            case productPicker:
                return productList.count
            case quantityPicker:
                return 100 // Numbers 1-100
            case metricPicker:
                return metrics.count
            default:
                return 0
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch pickerView {
            case productPicker:
                return productList[row]
            case quantityPicker:
                return "\(row + 1)" // Show 1-100
            case metricPicker:
                return metrics[row]
            default:
                return nil
            }
        }
        
    // MARK: - PickerView DataSource & Delegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case productPicker:
            let selectedProduct = productList[row]
            productName.text = selectedProduct
            selectedProductId = productDict[selectedProduct]
            fetchRemainingQuantity(for: selectedProductId)
        case quantityPicker:
            let selectedQuantity = row + 1
            quantitySold.text = "\(selectedQuantity)"
            validateQuantity(selectedQuantity)
        case metricPicker:
            metric.text = metrics[row]
        default:
            break
        }
    }
    
    private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    private func showSuccessAlert() {
            let alert = UIAlertController(title: "Success", message: "Sale recorded successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            present(alert, animated: true)
        }
    
    // MARK: - Validation
    private func validateQuantity(_ selectedQuantity: Int) {
        guard let remainingText = quantityRem.text,
              let remainingQuantity = Int(remainingText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) else {
            return
        }
        
        if selectedQuantity > remainingQuantity {
            showAlert(title: "Invalid Quantity", message: "Quantity sold cannot exceed remaining stock (\(remainingQuantity))")
            // Reset to maximum available quantity
            quantityPicker.selectRow(remainingQuantity - 1, inComponent: 0, animated: true)
            quantitySold.text = "\(remainingQuantity)"
        }
    }
    
    //Submit Sale
    // MARK: - Button Action
        @IBAction func submitSale(_ sender: UIButton) {
            print("Button pressed")
            guard let productId = selectedProductId,
                  let quantityText = quantitySold.text,
                  let quantity = Int(quantityText),
                  let metric = metric.text else {
                showAlert(title: "Missing Information", message: "Please fill all fields")
                return
            }
            
            // Final validation before submission
            guard let remainingText = quantityRem.text,
                  let remainingQuantity = Int(remainingText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) else {
                showAlert(title: "Error", message: "Could not read stock quantity")
                return
            }
            
            if quantity > remainingQuantity {
                showAlert(title: "Invalid Quantity", message: "Quantity sold cannot exceed remaining stock (\(remainingQuantity))")
                return
            }
            
            // Proceed with sale submission
            submitSaleToAPI(productId: productId, quantity: quantity, metric: metric)
        }
        
    private func submitSaleToAPI(productId: Int, quantity: Int, metric: String) {
        let saleData: [String: Any] = [
            "product_id": productId,
            "quantity_sold": quantity,
            "metric": metric
        ]
        
        print("Preparing to submit sale:", saleData)  // Debugging
        
        guard let url = URL(string: "http://127.0.0.1:5000/api/sales") else {
            showAlert(title: "Error", message: "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: saleData)
            print("Request body prepared:", String(data: request.httpBody!, encoding: .utf8) ?? "")  // Debugging
        } catch {
            showAlert(title: "Error", message: "Failed to prepare sale data")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error:", error.localizedDescription)  // Debugging
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")  // Debugging
                    self.showAlert(title: "Error", message: "Invalid server response")
                    return
                }
                
                print("Response status code:", httpResponse.statusCode)  // Debugging
                
                if let data = data {
                    print("Response data:", String(data: data, encoding: .utf8) ?? "")  // Debugging
                }
                
                if httpResponse.statusCode == 201 {
                    print("Sale recorded successfully")  // Debugging
                    self.showSuccessAlert()
                    // Refresh the product data
                    self.fetchProducts()
                } else {
                    let errorMessage: String
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        errorMessage = json["error"] as? String ?? "Unknown error"
                    } else {
                        errorMessage = "Failed to record sale (Status: \(httpResponse.statusCode))"
                    }
                    print("Error response:", errorMessage)  // Debugging
                    self.showAlert(title: "Error", message: errorMessage)
                }
            }
        }
        task.resume()
    }
        
        // MARK: - Models
        struct ProductStockResponse: Codable {
            let product_name: String
            let remaining_quantity: Int
        }
    
    func presentHalfScreen() {
        if let sheet = sheetPresentationController {
            // Create custom detent with your desired ratio (e.g., 0.4 for 40% of screen)
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("custom")) { context in
                // Return the height as a fraction of the maximum available height
                return context.maximumDetentValue * 0.45 // Adjust 0.4 to your preferred ratio (0.3-0.5)
            }
            
            sheet.detents = [customDetent] // Use only your custom detent
            sheet.prefersGrabberVisible = true
            
            // Optional: Prevent dismissing by dragging down
            sheet.largestUndimmedDetentIdentifier = .medium
        }
    }
    
    // - Present a separator line on the nav bar
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
    
    func borderedTextField() {
        // Remove any existing border style
        //productName.borderStyle = .none
        
        //Product Name
        // Add custom border
        productName.layer.borderWidth = 1.0
        productName.layer.borderColor = UIColor.systemGray2.cgColor
        productName.layer.cornerRadius = 8.0
        productName.clipsToBounds = true
        
        // Customize appearance
        productName.backgroundColor = .white
        productName.textColor = .darkText
        
        // Optional: Add placeholder styling
        productName.attributedPlaceholder = NSAttributedString(
            string: "Enter product name",
            attributes: [.foregroundColor: UIColor.systemGray2]
        )
        
        //Quantity rem
        // Add custom border
        quantityRem.layer.borderWidth = 1.0
        quantityRem.layer.borderColor = UIColor.systemGray2.cgColor
        quantityRem.layer.cornerRadius = 8.0
        quantityRem.clipsToBounds = true
        
        // Customize appearance
        quantityRem.backgroundColor = .white
        quantityRem.textColor = .darkText
        
        //Quantity sold
        quantitySold.layer.borderWidth = 1.0
        quantitySold.layer.borderColor = UIColor.systemGray2.cgColor
        quantitySold.layer.cornerRadius = 8.0
        quantitySold.clipsToBounds = true
        
        // Customize appearance
        quantitySold.backgroundColor = .white
        quantitySold.textColor = .darkText
        
        //Metric
        metric.layer.borderWidth = 1.0
        metric.layer.borderColor = UIColor.systemGray2.cgColor
        metric.layer.cornerRadius = 8.0
        metric.clipsToBounds = true
        
        // Customize appearance
        metric.backgroundColor = .white
        metric.textColor = .darkText
        
    }
    
    func setupBackgroundCard() {
        // Card styling
        backgroundCard.backgroundColor = .white
        backgroundCard.layer.cornerRadius = 12
        backgroundCard.layer.shadowColor = UIColor.black.cgColor
        backgroundCard.layer.shadowOpacity = 0.1
        backgroundCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundCard.layer.shadowRadius = 6
        backgroundCard.clipsToBounds = false
        
        // Make sure it's behind all other elements
        view.sendSubviewToBack(backgroundCard)
        
        // Add padding/margins
        backgroundCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundCard.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 40),
            backgroundCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backgroundCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            backgroundCard.bottomAnchor.constraint(equalTo: metric.bottomAnchor, constant: 80)
        ])
        
        // Adjust text field backgrounds to be transparent
        [productName, quantityRem, quantitySold, metric].forEach { textField in
            textField?.backgroundColor = .clear
        }
    }
    
    func styleSalesButton() {
        // Basic button styling
        buttonSales.backgroundColor = UIColor.black
        buttonSales.setTitleColor(.white, for: .normal)
        buttonSales.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .highlighted)
        
        // Font setup (Roboto)
        if let robotoFont = UIFont(name: "Roboto-Medium", size: 16) {
            buttonSales.titleLabel?.font = robotoFont
        } else {
            buttonSales.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        
        // Smooth rounded edges (pill shape)
        buttonSales.layer.cornerRadius = 12 // More rounded than the card's 12
        buttonSales.clipsToBounds = true
        
        // Shadow that matches the card's style but more subtle
        buttonSales.layer.shadowColor = UIColor.black.cgColor
        buttonSales.layer.shadowOffset = CGSize(width: 0, height: 2)
        buttonSales.layer.shadowRadius = 4
        buttonSales.layer.shadowOpacity = 0.1
        
        // Position the button within the card
        buttonSales.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonSales.bottomAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: -20),
            buttonSales.centerXAnchor.constraint(equalTo: backgroundCard.centerXAnchor),
            buttonSales.widthAnchor.constraint(equalTo: backgroundCard.widthAnchor, multiplier: 0.9),
            buttonSales.heightAnchor.constraint(equalToConstant: 48) // Fixed the typo here (was "constraint")
        ])
        
        // Add press animation
        buttonSales.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        buttonSales.addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
    }

    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.buttonSales.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.buttonSales.alpha = 0.9
        }
    }

    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.buttonSales.transform = .identity
            self.buttonSales.alpha = 1.0
        }
    }

}
