import UIKit

class ViewInbounds: UIViewController {
    
    private var allInbounds: [Inbound] = []
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBOutlet weak var filterOptions: UIBarButtonItem!
    
     private var inbounds: [Inbound] = []
     private var sections: [MonthSection] = []
     
     override func viewDidLoad() {
     super.viewDidLoad()
     title = "Inbounds"
     
         
     activateFilterButton()
     setUpTable()
     setupTableView()
     //setupCustomBackButton()
     inboundNavBarTitleColor()
     fetchAllInbounds()
     }
    
    
    private func activateFilterButton(){
        // Add this line to connect your filter button
        filterOptions.target = self
        filterOptions.action = #selector(showFilterOptions)
    }
    
    @objc private func showFilterOptions() {
        let alert = UIAlertController(title: "Filter Inbounds",
                                    message: "Select a month to filter",
                                    preferredStyle: .actionSheet)
        
        // Add actions for each available month
        let availableMonths = sections.map { $0.month }.sorted(by: >)
        
        for month in availableMonths {
            alert.addAction(UIAlertAction(title: month, style: .default) { [weak self] _ in
                self?.applyMonthFilter(month)
            })
        }
        
        // Add "All Months" option
        alert.addAction(UIAlertAction(title: "All Months", style: .default) { [weak self] _ in
            self?.resetFilter()
        });
        
        // Add cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = filterOptions
        }
        
        present(alert, animated: true)
    }

    private func applyMonthFilter(_ month: String) {
        guard let section = sections.first(where: { $0.month == month }) else { return }
        
        // Filter to show only the selected month
        sections = [section]
        tableView.reloadData()
        
        // Update UI to show active filter
        navigationItem.title = "Inbounds (\(month))"
        filterOptions.image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
    }

    private func resetFilter() {
        // Reset to show all months
        groupInboundsByMonth()
        tableView.reloadData()
        
        // Reset UI
        navigationItem.title = "Inbounds"
        filterOptions.image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
    }
     // MARK: - Setup
     
      private func setupTableView() {
      tableView.register(AllInboundsTableViewCell.self, forCellReuseIdentifier: AllInboundsTableViewCell.reuseIdentifier)
      tableView.dataSource = self
      tableView.delegate = self
      tableView.separatorStyle = .none
      tableView.rowHeight = UITableView.automaticDimension
      tableView.estimatedRowHeight = 60
      }
    
    private func setUpTable () {
        // Fix content insets
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        // Make sure table view fills the screen
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10), // Use negative value to pull up
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        
    }
      
     // MARK: - Data Fetching
    private func fetchAllInbounds() {
        guard let url = URL(string: "http://localhost:5000/api/fetchallinbounds") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching inbounds: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let inbounds = try decoder.decode([Inbound].self, from: data)
                
                DispatchQueue.main.async {
                    self.allInbounds = inbounds // Store original data
                    self.groupInboundsByMonth()
                    self.tableView.reloadData()
                }
            } catch {
                print("Error decoding inbounds: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func groupInboundsByMonth() {
        // Always work with the complete dataset
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let sortedInbounds = allInbounds.sorted {
            let date1 = parseDate(from: $0.createdAt, formatter: dateFormatter)
            let date2 = parseDate(from: $1.createdAt, formatter: dateFormatter)
            return date1 > date2
        }
        
        let grouped = Dictionary(grouping: sortedInbounds) { (inbound) -> String in
            let date = parseDate(from: inbound.createdAt, formatter: dateFormatter)
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: date)
        }
        
        sections = grouped.map { MonthSection(month: $0.key, inbounds: $0.value) }
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
    
     
     // MARK: - Navigation Styling
     private func inboundNavBarTitleColor() {
     let inboundTitleAppearance = UINavigationBarAppearance()
     inboundTitleAppearance.configureWithOpaqueBackground()
     inboundTitleAppearance.titleTextAttributes = [
     .font: UIFont.Roboto(ofSize: 18, weight: .bold)
     ]
     
     navigationController?.navigationBar.standardAppearance = inboundTitleAppearance
     navigationController?.navigationBar.scrollEdgeAppearance = inboundTitleAppearance
     navigationController?.navigationBar.compactAppearance = inboundTitleAppearance
     navigationController?.navigationBar.isTranslucent = false
     navigationController?.navigationBar.tintColor = UIColor(red: 139/255, green: 24/255, blue: 8/255, alpha: 1.0)
     }
     
     private func setupCustomBackButton() {
     let backButton = UIButton(type: .custom)
     
     // Set the background color
     backButton.backgroundColor = UIColor(red: 139/255, green: 24/255, blue: 8/255, alpha: 1.0)
     
     // Set the arrow icon
     let arrowImage = UIImage(systemName: "arrow.left")?.withRenderingMode(.alwaysTemplate)
     backButton.setImage(arrowImage, for: .normal)
     backButton.tintColor = .white
     
     // This is crucial for maintaining circular shape
     backButton.translatesAutoresizingMaskIntoConstraints = false
     
     // Create a container view to hold the button
     let containerView = UIView()
     containerView.translatesAutoresizingMaskIntoConstraints = false
     
     // Add button to container
     containerView.addSubview(backButton)
     
     // Set fixed size constraints for perfect circle
     NSLayoutConstraint.activate([
     backButton.widthAnchor.constraint(equalToConstant: 30),
     backButton.heightAnchor.constraint(equalToConstant: 30),
     backButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
     backButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
     
     // Container needs to be slightly larger to accommodate the button
     containerView.widthAnchor.constraint(equalToConstant: 44),
     containerView.heightAnchor.constraint(equalToConstant: 44)
     ])
     
     // Make it circular
     backButton.layer.cornerRadius = 15  // Half of 30
     backButton.clipsToBounds = true
     
     // Adjust content insets
     backButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
     
     // Add action
     backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
     
     // Wrap the container in a UIBarButtonItem
     let barButtonItem = UIBarButtonItem(customView: containerView)
     navigationItem.leftBarButtonItem = barButtonItem
     }
     
     @objc private func backButtonTapped() {
     navigationController?.popViewController(animated: true)
     }
     }
     
      // MARK: - TableView DataSource & Delegate
      extension ViewInbounds: UITableViewDataSource, UITableViewDelegate {
      func numberOfSections(in tableView: UITableView) -> Int {
      return sections.count
      }
      
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return sections[section].inbounds.count
      }
      
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       guard let cell = tableView.dequeueReusableCell(
       withIdentifier: AllInboundsTableViewCell.reuseIdentifier,
       for: indexPath
       ) as? AllInboundsTableViewCell else {
       return UITableViewCell()
       }
       
       let inbound = sections[indexPath.section].inbounds[indexPath.row]
       cell.configure(with: inbound)
       return cell
       }
     
     
     
      func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let headerView = UIView()
      headerView.backgroundColor = .white
      
      let label = UILabel()
      label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
      label.textColor = UIColor(red: 139/255, green: 24/255, blue: 8/255, alpha: 1.0)
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
     struct Inbound: Codable {
     let productName: String
     let quantity: Int
     let createdAt: String
     
     enum CodingKeys: String, CodingKey {
     case productName = "product_name"
     case quantity
     case createdAt = "created_at"
     }
     }
     
     struct MonthSection {
     let month: String
     let inbounds: [Inbound]
     }

extension UIFont {
    enum RobotoWeight {
        case regular, medium, bold
    }
    
    static func Roboto(ofSize size: CGFloat, weight: RobotoWeight) -> UIFont {
        let fontName: String
        switch weight {
        case .regular:
            fontName = "Roboto-Regular"
        case .medium:
            fontName = "Roboto-Medium"
        case .bold:
            fontName = "Roboto-Bold"
        }
        
        guard let font = UIFont(name: fontName, size: size) else {
            print("Warning: Failed to load Roboto font. Falling back to system font.")
            return UIFont.systemFont(ofSize: size, weight: weight == .bold ? .bold : .regular)
        }
        return font
    }
}


