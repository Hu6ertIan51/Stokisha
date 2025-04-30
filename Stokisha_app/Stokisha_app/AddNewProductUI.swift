//
//  AddNewProduct.swift
//  Stokisha
//
//  Created by Ian Omondi on 07/03/2025.
//

import UIKit

class AddNewProductUI: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var submitButton: UIButton!
    // Declare UI elements at class level so they are accessible in child classes
    let supplierNameField = UITextField()
    let phoneNumberField = UITextField()
    let productNameField = UITextField()
    let productCategoryLabel = UILabel()
    let descriptionField = UITextField()
    let costPriceField = UITextField()
    let sellingPriceField = UITextField()
    let supplierContainer = UIView() 

    
    let countryPickerView = UIPickerView()
    let productCategoryPickerView = UIPickerView()
    
    let countryCodeField = UITextField()
    let productCategoryField = UITextField()
    
    let eastAfricanCountries: [(name: String, code: String, flag: String)] = [
        ("Kenya", "+254", "🇰🇪"),
        ("Uganda", "+256", "🇺🇬"),
        ("Tanzania", "+255", "🇹🇿"),
        ("Rwanda", "+250", "🇷🇼"),
        ("Burundi", "+257", "🇧🇮"),
        ("South Sudan", "+211", "🇸🇸"),
        ("Ethiopia", "+251", "🇪🇹"),
        ("Somalia", "+252", "🇸🇴")
    ]
    
    let productCategories = ["Electronics", "Clothing", "Home Appliances", "Books", "Beauty", "Sports"]
    
    
    //let supplierNameField = UITextField()
    //let phoneNumberField = UITextField()
    let countryCodeLabel = UILabel()
    //let productCategoryLabel = UILabel()
    
    let countryPicker = UIPickerView()
    let categoryPicker = UIPickerView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PRODUCTS"
        
        setupNavigationBarFont()
        setupSeparatorLine()
        setupProductDetailsForm()
        setupPricingInformationForm()
        setupSupplierInformationForm()
        setupSubmitButton()

        // Assign delegate & data source
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        productCategoryPickerView.delegate = self
        productCategoryPickerView.dataSource = self

        // Ensure correct input views are set
        productCategoryField.inputView = productCategoryPickerView

    }
    
    func setupSeparatorLine(){
        let separatorLine = UIView()
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
    
    func setupNavigationBarFont() {
        if let customFont = UIFont(name: "Roboto-Bold", size: 15) {
            navigationController?.navigationBar.titleTextAttributes = [
                NSAttributedString.Key.font: customFont,
                NSAttributedString.Key.foregroundColor: UIColor.black // Customize text color
            ]
        }
    }
    
    func setupProductDetailsForm() {
        let formContainer = UIView()
        formContainer.layer.borderWidth = 1
        formContainer.layer.borderColor = UIColor.gray.cgColor
        formContainer.layer.cornerRadius = 10
        formContainer.backgroundColor = UIColor.systemGray6
        formContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formContainer)

        let robotoFont = UIFont(name: "Roboto-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)

        productNameField.placeholder = "Product Name"
        productNameField.borderStyle = .roundedRect
        productNameField.font = robotoFont
        productNameField.translatesAutoresizingMaskIntoConstraints = false

        productCategoryField.placeholder = "Product Category"
        productCategoryField.borderStyle = .roundedRect
        productCategoryField.font = robotoFont
        productCategoryField.translatesAutoresizingMaskIntoConstraints = false
        productCategoryField.isUserInteractionEnabled = true
        productCategoryField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showCategoryPicker)))

        descriptionField.placeholder = "Description"
        descriptionField.borderStyle = .roundedRect
        descriptionField.font = robotoFont
        descriptionField.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [productNameField, productCategoryField, descriptionField])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        formContainer.addSubview(stackView)

        NSLayoutConstraint.activate([
            formContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            formContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            formContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            formContainer.heightAnchor.constraint(equalToConstant: 200),

            stackView.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: formContainer.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor, constant: -10),

            productNameField.heightAnchor.constraint(equalToConstant: 30),
            productCategoryField.heightAnchor.constraint(equalToConstant: 30),
            descriptionField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    
    @objc func showCategoryPicker() {
        let alert = UIAlertController(title: "Select Product Category", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        // Configure the product category picker
        productCategoryPickerView.frame = CGRect(x: 0, y: 50, width: 270, height: 150)
        alert.view.addSubview(productCategoryPickerView)
        
        let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
            let selectedRow = self.productCategoryPickerView.selectedRow(inComponent: 0)
            let selectedCategory = self.productCategories[selectedRow]
            self.productCategoryField.text = selectedCategory // ✅ Update text field
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(selectAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func setupPricingInformationForm() {
        let pricingContainer = UIView()
        pricingContainer.layer.borderWidth = 1
        pricingContainer.layer.borderColor = UIColor.gray.cgColor
        pricingContainer.layer.cornerRadius = 10
        pricingContainer.backgroundColor = UIColor.systemGray6
        pricingContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pricingContainer)

        let robotoFont = UIFont(name: "Roboto-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)

        // Use class-level properties (No 'let' before them!)
        costPriceField.placeholder = "Cost Price"
        costPriceField.borderStyle = .roundedRect
        costPriceField.keyboardType = .decimalPad
        costPriceField.translatesAutoresizingMaskIntoConstraints = false
        costPriceField.font = robotoFont

        sellingPriceField.placeholder = "Selling Price"
        sellingPriceField.borderStyle = .roundedRect
        sellingPriceField.keyboardType = .decimalPad
        sellingPriceField.translatesAutoresizingMaskIntoConstraints = false
        sellingPriceField.font = robotoFont

        let stackView = UIStackView(arrangedSubviews: [costPriceField, sellingPriceField])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pricingContainer.addSubview(stackView)

        NSLayoutConstraint.activate([
            pricingContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            pricingContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            pricingContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 340),
            pricingContainer.heightAnchor.constraint(equalToConstant: 100),

            stackView.leadingAnchor.constraint(equalTo: pricingContainer.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: pricingContainer.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: pricingContainer.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: pricingContainer.bottomAnchor, constant: -10),

            costPriceField.heightAnchor.constraint(equalToConstant: 30),
            sellingPriceField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    
    // Supplier information
    func setupSupplierInformationForm() {
            let supplierContainer = UIView()
            supplierContainer.layer.borderWidth = 1
            supplierContainer.layer.borderColor = UIColor.gray.cgColor
            supplierContainer.layer.cornerRadius = 10
            supplierContainer.backgroundColor = UIColor.systemGray6
            supplierContainer.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(supplierContainer)
            
            // Supplier Name Field
            supplierNameField.placeholder = "Supplier Name"
            supplierNameField.borderStyle = .roundedRect
            supplierNameField.translatesAutoresizingMaskIntoConstraints = false
            supplierContainer.addSubview(supplierNameField)

            // Country Code Label
            countryCodeLabel.text = "🇰🇪 +254"
            countryCodeLabel.font = UIFont.systemFont(ofSize: 16)
            countryCodeLabel.textAlignment = .center
            countryCodeLabel.layer.borderWidth = 1
            countryCodeLabel.layer.borderColor = UIColor.gray.cgColor
            countryCodeLabel.layer.cornerRadius = 5
            countryCodeLabel.layer.masksToBounds = true
            countryCodeLabel.isUserInteractionEnabled = true
            countryCodeLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCountryPicker))
            countryCodeLabel.addGestureRecognizer(tapGesture)

            // Phone Number Field
            phoneNumberField.placeholder = "Phone Number"
            phoneNumberField.borderStyle = .roundedRect
            phoneNumberField.keyboardType = .phonePad
            phoneNumberField.translatesAutoresizingMaskIntoConstraints = false
            
            // StackView for Phone Section
            let phoneStackView = UIStackView(arrangedSubviews: [countryCodeLabel, phoneNumberField])
            phoneStackView.axis = .horizontal
            phoneStackView.spacing = 8
            phoneStackView.distribution = .fillProportionally
            phoneStackView.alignment = .fill
            phoneStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Main StackView inside Supplier Container
            let mainStackView = UIStackView(arrangedSubviews: [supplierNameField, phoneStackView])
            mainStackView.axis = .vertical
            mainStackView.spacing = 12
            mainStackView.translatesAutoresizingMaskIntoConstraints = false
            supplierContainer.addSubview(mainStackView)
            
            
            
            NSLayoutConstraint.activate([
                supplierContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                supplierContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                supplierContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 510),
                supplierContainer.heightAnchor.constraint(equalToConstant: 100),
                
                mainStackView.leadingAnchor.constraint(equalTo: supplierContainer.leadingAnchor, constant: 10),
                mainStackView.trailingAnchor.constraint(equalTo: supplierContainer.trailingAnchor, constant: -10),
                mainStackView.topAnchor.constraint(equalTo: supplierContainer.topAnchor, constant: 10),
                mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: supplierContainer.bottomAnchor, constant: -10),
                
                supplierNameField.heightAnchor.constraint(equalToConstant: 30),
                
                countryCodeLabel.widthAnchor.constraint(equalToConstant: 80),
                phoneNumberField.heightAnchor.constraint(equalToConstant: 30),
                
            ])
            
            countryPicker.delegate = self
            countryPicker.dataSource = self
        }

    
    @objc func showCountryPicker() {
            let alert = UIAlertController(title: "Select Country", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
            
            countryPicker.frame = CGRect(x: 0, y: 50, width: 270, height: 150)
            alert.view.addSubview(countryPicker)
            
            let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
                let selectedRow = self.countryPicker.selectedRow(inComponent: 0)
                let country = self.eastAfricanCountries[selectedRow]
                self.countryCodeLabel.text = "\(country.flag) \(country.code)"
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(selectAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
    
    // MARK: - UIPickerView DataSource & Delegate

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return pickerView == countryPicker ? eastAfricanCountries.count : productCategories.count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return pickerView == countryPicker ? "\(eastAfricanCountries[row].flag) \(eastAfricanCountries[row].name) (\(eastAfricanCountries[row].code))"
                : productCategories[row]
        }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == countryPicker {
            let country = eastAfricanCountries[row]
            countryCodeLabel.text = "\(country.flag) \(country.code)"
        } else if pickerView == productCategoryPickerView {
            let category = productCategories[row]
            productCategoryField.text = category // ✅ Correctly updating the text field
        }
    }
    
    func setupSubmitButton() {
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = UIColor.black
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.titleLabel?.font = UIFont(name: "Roboto-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 375),
            submitButton.heightAnchor.constraint(equalToConstant: 40),

            // ✅ Move the button down (adjust the value as needed)
            submitButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 680)
        ])

        submitButton.addTarget(self, action: #selector(saveProductToDatabase), for: .touchUpInside)
    }

    
    // MARK: - Save Product to Database
    @objc func saveProductToDatabase() {
        print("Submit button pressed! Gathering data...")

        // Print raw field values before validation
        print("Supplier Name: \(supplierNameField.text ?? "nil")")
        print("Phone Number: \(phoneNumberField.text ?? "nil")")
        print("Product Name: \(productNameField.text ?? "nil")")
        print("Product Category: \(productCategoryField.text ?? "nil")")
        print("Description: \(descriptionField.text ?? "nil")")
        print("Cost Price: \(costPriceField.text ?? "nil")")
        print("Selling Price: \(sellingPriceField.text ?? "nil")")

        guard let supplierName = supplierNameField.text, !supplierName.isEmpty,
              let phoneNumber = phoneNumberField.text, !phoneNumber.isEmpty, // Keep as String
              let productName = productNameField.text, !productName.isEmpty,
              let productCategory = productCategoryField.text, !productCategory.isEmpty,
              let productDescription = descriptionField.text, !productDescription.isEmpty,
              let costPriceString = costPriceField.text, !costPriceString.isEmpty,
              let sellingPriceString = sellingPriceField.text, !sellingPriceString.isEmpty,
              let costPrice = Double(costPriceString.replacingOccurrences(of: ",", with: ".")), // Ensure correct decimal format
              let sellingPrice = Double(sellingPriceString.replacingOccurrences(of: ",", with: ".")) else {

            print("Missing or invalid input!")
            showAlert(title: "Missing or Invalid Input", message: "Please enter all fields correctly.")
            return
        }

        // Ensure phone number contains only digits (but keep it as a String)
        let phoneCharacterSet = CharacterSet.decimalDigits
        if phoneNumber.rangeOfCharacter(from: phoneCharacterSet.inverted) != nil {
            print("Invalid phone number format!")
            showAlert(title: "Invalid Phone Number", message: "Please enter a valid phone number.")
            return
        }

        print("All fields are valid. Preparing to send data...")

        let productData: [String: Any] = [
            "supplier_name": supplierName,
            "phone_number": phoneNumber, // Keep as String
            "product_name": productName,
            "product_category": productCategory,
            "description": productDescription,
            "cost_price": String(format: "%.2f", costPrice), // Format to 2 decimal places
            "selling_price": String(format: "%.2f", sellingPrice)
        ]

        sendToFlaskAPI(productData)


        print("Submit button was pressed!")
    }

        // MARK: - Send Data to Flask API
    private func sendToFlaskAPI(_ data: [String: Any]) {
        guard let url = URL(string: "http://127.0.0.1:5000/api/products") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: data, options: []) else {
            print("Failed to serialize JSON")
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network Error:", error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response Code:", httpResponse.statusCode)
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response:", responseString)
                    }
                    
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    } else {
                        print("Failed to save product.")
                    }
                }
            }
        }
        
        task.resume()
    }

        // MARK: - Show Alert
        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)

            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
}


    




