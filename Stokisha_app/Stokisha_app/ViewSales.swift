import UIKit

class ViewSales: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterOptions: UIBarButtonItem!
    
    private var allSales: [Sale] = []
    private var sales: [Sale] = []
    private var sections: [MonthSections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sales"
        
        activateFilterButton()
        setUpTable()
        setupTableView()
        salesNavBarTitleColor()
        fetchAllSales()
    }
    
    private func activateFilterButton() {
        filterOptions.target = self
        filterOptions.action = #selector(showFilterOptions)
    }
    
    @objc private func showFilterOptions() {
        let alert = UIAlertController(title: "Filter Sales",
                                    message: "Select a month to filter",
                                    preferredStyle: .actionSheet)
        
        let availableMonths = sections.map { $0.month }.sorted(by: >)
        
        for month in availableMonths {
            alert.addAction(UIAlertAction(title: month, style: .default) { [weak self] _ in
                self?.applyMonthFilter(month)
            }
            )};
        
        alert.addAction(UIAlertAction(title: "All Months", style: .default) { [weak self] _ in
            self?.resetFilter()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = filterOptions
        }
        
        present(alert, animated: true)
    }
    
    private func applyMonthFilter(_ month: String) {
        guard let section = sections.first(where: { $0.month == month }) else { return }
        sections = [section]
        tableView.reloadData()
        navigationItem.title = "Sales (\(month))"
        filterOptions.image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
    }
    
    private func resetFilter() {
        groupSalesByMonth()
        tableView.reloadData()
        navigationItem.title = "Sales"
        filterOptions.image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
    }
    
    private func setupTableView() {
        tableView.register(AllSalesTableViewCell.self, forCellReuseIdentifier: AllSalesTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    private func setUpTable() {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchAllSales() {
        guard let url = URL(string: "http://localhost:5000/api/all-sales") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching sales: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No sales data received")
                return
            }
            
            // Debug print
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw API response:", jsonString)
            }
            
            do {
                let response = try JSONDecoder().decode(SalesResponse.self, from: data)
                if response.success {
                    DispatchQueue.main.async {
                        self.allSales = response.data
                        self.groupSalesByMonth()
                        self.tableView.reloadData()
                    }
                } else {
                    print("API returned error: \(response.error ?? "Unknown error")")
                }
            } catch {
                print("Error decoding sales: \(error)")
            }
        }.resume()
    }
    
    private func groupSalesByMonth() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let sortedSales = allSales.sorted {
            let date1 = parseDate(from: $0.saleDate, formatter: dateFormatter)
            let date2 = parseDate(from: $1.saleDate, formatter: dateFormatter)
            return date1 > date2
        }
        
        let grouped = Dictionary(grouping: sortedSales) { (sale) -> String in
            let date = parseDate(from: sale.saleDate, formatter: dateFormatter)
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: date)
        }
        
        sections = grouped.map { MonthSections(month: $0.key, sales: $0.value) }
            .sorted {
                let date1 = parseDate(from: $0.month, monthFormat: "MMMM yyyy", formatter: dateFormatter)
                let date2 = parseDate(from: $1.month, monthFormat: "MMMM yyyy", formatter: dateFormatter)
                return date1 > date2
            }
    }
    
    private func parseDate(from string: String, monthFormat: String? = nil, formatter: DateFormatter) -> Date {
        if let monthFormat = monthFormat {
            formatter.dateFormat = monthFormat
        } else {
            // Try multiple possible date formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy/MM/dd HH:mm:ss",
                "MM/dd/yyyy HH:mm:ss"
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: string) {
                    return date
                }
            }
        }
        
        // If we get here and it's a month string, try parsing just the year
        if monthFormat != nil, let year = Int(string.components(separatedBy: " ").last ?? "") {
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            return Calendar.current.date(from: components) ?? Date.distantPast
        }
        
        // Fallback for truly unparseable dates
        print("Warning: Could not parse date string: \(string)")
        return Date.distantPast
    }
    
    private func salesNavBarTitleColor() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.Roboto(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor(red: 0/255, green: 28/255, blue: 45/255, alpha: 1.0)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(red: 0/255, green: 28/255, blue: 45/255, alpha: 1.0)
    }
}

// MARK: - TableView DataSource & Delegate
extension ViewSales: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].sales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AllSalesTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? AllSalesTableViewCell else {
            return UITableViewCell()
        }
        
        let sale = sections[indexPath.section].sales[indexPath.row]
        cell.configure(with: sale)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .tertiarySystemBackground : .white
        }
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0/255, green: 28/255, blue: 45/255, alpha: 1.0)
        label.text = sections[section].month
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - Data Models
struct Sale: Codable {
    let productName: String
    let quantitySold: Int
    let metric: String  // Add this field
    let saleDate: String
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case quantitySold = "quantity_sold"
        case metric       // Add this
        case saleDate = "sale_date"
    }
}

struct MonthSections {
    let month: String
    let sales: [Sale]
    
    // Add this initializer for proper sorting
    init(month: String, sales: [Sale]) {
        self.month = month
        self.sales = sales.sorted {
            let date1 = ISO8601DateFormatter().date(from: $0.saleDate) ?? Date.distantPast
            let date2 = ISO8601DateFormatter().date(from: $1.saleDate) ?? Date.distantPast
            return date1 > date2
        }
    }
}

struct SalesResponse: Codable {
    let success: Bool
    let data: [Sale]
    let error: String?
}



