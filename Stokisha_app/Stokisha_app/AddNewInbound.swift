//
//  AddNewInbound.swift
//  Stokisha
//
//  Created by Ian Omondi on 22/03/2025.
//

import UIKit



class AddNewInbound: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    weak var delegate: InboundDelegate?
    
    struct Product: Codable {
        let product_name: String
        let product_id: Int
    }
    
    
    
    //Outlets and variables
    
    @IBOutlet weak var inboundDetails: UIView!
    
    @IBOutlet weak var productName: UITextField!
    
    @IBOutlet weak var stockDetails: UIView!
    
    @IBOutlet weak var stockUnit: UITextField!
    
    @IBOutlet weak var stockQuantity: UITextField!
    
    @IBOutlet weak var submitInboundButton: UIButton!
    
    //UIpciker for the products
    var pickerView = UIPickerView()
    var unitPickerView = UIPickerView()
    var productList: [String] = []
    let stockUnits = ["kg", "liters", "pieces", "boxes"]
    
    var products: [Product] = []   // Store full product data
    var productDict: [String: Int] = [:]  // Map product_name to product_id
    var selectedProductId: Int?  // Stores the selected product_id
    
    
    var quantityValue: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentHalfScreen()
        setupSeparatorLine()
        inboundDetailsView()
        setupPicker()
        fetchProducts()
        stockDetailsView()
        setupUnitPicker()
        setupQuantityPicker()
        setupSubmitInboundButton()
        
    }
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setupSubmitInboundButton() {
        submitInboundButton.titleLabel?.font = UIFont(name: "Roboto-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        submitInboundButton.addTarget(self, action: #selector(saveinboundToDatabase), for: .touchUpInside)
        
    }
    
    @objc func saveinboundToDatabase() {
        guard let stockUnit = stockUnit.text, !stockUnit.isEmpty,
              let stockQuantityString = stockQuantity.text, !stockQuantityString.isEmpty,
              let stockQuantity = Int(stockQuantityString),
              let selectedProductId = selectedProductId else {
            showAlert(title: "Missing or Invalid Input", message: "Please enter all fields correctly.")
            return
        }

        let inboundData: [String: Any] = [
            "product_id": selectedProductId,
            "stock_unit": stockUnit,
            "quantity": stockQuantity
        ]

        sendInboundStockToAPI(inboundData) { success in
            DispatchQueue.main.async {
                if success {
                    // Notify delegate first
                    self.delegate?.didAddNewInbound(withMessage: "Inbound added successfully ✅")
                    
                    // Dismiss AFTER a slight delay (0.5s) to allow toast to appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.dismiss(animated: true)
                    }
                } else {
                    self.showAlert(title: "Error", message: "Failed to add inbound")
                }
            }
        }
    }
    
    private func sendInboundStockToAPI(_ data: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:5000/api/inbounds") else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: data, options: []) else {
            print("Failed to serialize JSON")
            completion(false)
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error:", error.localizedDescription)
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Code:", httpResponse.statusCode)
                completion(httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    // Setup picker for stock unit
    func setupUnitPicker() {
        unitPickerView.delegate = self
        unitPickerView.dataSource = self
        
        stockUnit.inputView = unitPickerView
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissPicker))
        toolbar.setItems([doneButton], animated: true)
        
        stockUnit.inputAccessoryView = toolbar
    }
    
    // Setup picker for stock quantity with stepper-like functionality
    // Store reference to quantity label
    var quantityLabel: UILabel!
    
    func setupQuantityPicker() {
        let pickerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
        
        quantityLabel = UILabel(frame: CGRect(x: 0, y: 10, width: pickerContainer.frame.width, height: 40))
        quantityLabel.textAlignment = .center
        quantityLabel.font = UIFont.systemFont(ofSize: 18)
        quantityLabel.text = "\(quantityValue)"
        
        let segmentedControl = UISegmentedControl(items: ["−", "+"])
        segmentedControl.frame = CGRect(x: pickerContainer.frame.width / 4, y: 60, width: pickerContainer.frame.width / 2, height: 40)
        segmentedControl.addTarget(self, action: #selector(quantityStepperChanged(_:)), for: .valueChanged)
        
        pickerContainer.addSubview(quantityLabel)
        pickerContainer.addSubview(segmentedControl)
        
        stockQuantity.inputView = pickerContainer
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissPicker))
        toolbar.setItems([doneButton], animated: true)
        
        stockQuantity.inputAccessoryView = toolbar
    }
    
    
    // Stepper logic for quantity selection
    @objc func quantityStepperChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {  // Decrease
            quantityValue = max(1, quantityValue - 1)
        } else {  // Increase
            quantityValue += 1
        }
        
        // Update both the label and text field
        quantityLabel.text = "\(quantityValue)"
        stockQuantity.text = "\(quantityValue)"
        
        // Reset selection (prevents reusing the same tap)
        sender.selectedSegmentIndex = UISegmentedControl.noSegment
    }
    
    
    
    func stockDetailsView() {
        stockDetails.layer.cornerRadius = 12  // Rounded corners
        stockDetails.layer.borderWidth = 0.9  // Border width
        stockDetails.backgroundColor = UIColor.systemGray6
        stockDetails.layer.masksToBounds = true
    }
    
    func fetchProducts() {
        guard let url = URL(string: "http://127.0.0.1:5000/api/fetch-products") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching products: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let fetchedProducts = try JSONDecoder().decode([String: Int].self, from: data)

                DispatchQueue.main.async {
                    // Update product list and dictionary
                    self.productList = Array(fetchedProducts.keys)
                    self.productDict = fetchedProducts

                    print("Product List Updated: \(self.productList)")  // Debugging

                    // Reload the picker
                    self.pickerView.reloadAllComponents()
                    
                    // Select the first row automatically
                    if !self.productList.isEmpty {
                        self.pickerView.selectRow(0, inComponent: 0, animated: false)
                        
                        // Update the UI text field to show the first product
                        let firstProduct = self.productList[0]
                        self.productName.text = firstProduct
                        
                        // Set selectedProductId based on first product
                        self.selectedProductId = self.productDict[firstProduct]
                        print("Default selected product: \(firstProduct), ID: \(self.selectedProductId ?? -1)")
                    }
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    
    //Fetches the products from the DB
    func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self

        // Assign picker to the text field
        productName.inputView = pickerView

        // Add toolbar with "Done" button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissPicker))

        toolbar.setItems([doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        productName.inputAccessoryView = toolbar

        // Fetch products
        fetchProducts()  // Now fetches data properly before selecting the first row
    }
    
    @objc func dismissPicker() {
        view.endEditing(true)
    }
    
    func inboundDetailsView() {
        inboundDetails.layer.cornerRadius = 12  // Rounded corners
        inboundDetails.layer.borderWidth = 0.9  // Border width
        inboundDetails.backgroundColor = UIColor.systemGray6
        inboundDetails.layer.masksToBounds = true
    }
    
    func presentHalfScreen() {
        // Configure modal to be half-screen
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()] // Sets modal to half-screen
            sheet.prefersGrabberVisible = true
        }
    }
    
    //Line to separate the Nav bar from the safe area
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
    
    // Picker Delegate Functions
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Return number of rows depending on which picker is being used
        return pickerView == unitPickerView ? stockUnits.count : productList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == unitPickerView {
            return stockUnits[row]
        } else {
            let productName = productList[row]
            print("Row \(row): \(productName)")  // Debugging line
            return productName
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Check which picker view triggered the selection
        if pickerView == unitPickerView {
            // Handle unit picker selection
            guard row < stockUnits.count else { return }
            stockUnit.text = stockUnits[row]  // Update stockUnit text field with selected value
        } else {
            // Handle product picker selection
            guard row < productList.count else { return }
            let selectedProductName = productList[row]  // Get the selected product name
            productName.text = selectedProductName  // Update the productName text field with selected product name
            
            // Look up the product_id using the productDict
            if let selectedId = productDict[selectedProductName] {
                selectedProductId = selectedId  // Set the selected product ID
                print("Selected Product: \(selectedProductName), ID: \(selectedProductId ?? -1)")
            } else {
                print("Product ID not found for: \(selectedProductName)")
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Only one component in each picker
        return 1
    }
}
