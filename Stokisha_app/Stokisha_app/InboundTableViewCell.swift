import UIKit

class InboundTableViewCell: UITableViewCell {
    
    let initialsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.backgroundColor = UIColor(red: 139/255, green: 24/255, blue: 8/255, alpha: 1.0)
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.clipsToBounds = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        return label
    }()
    
    let productLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Roboto-Regular", size: 17)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)  // Use system font
        label.textColor = .black
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Roboto-Regular", size: 12)
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupCellAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellAppearance() {
        contentView.backgroundColor = .white
        backgroundColor = .white
    }
    
    private func setupViews() {
        [initialsLabel, productLabel, quantityLabel, timeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // Initials label (circle)
            initialsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            initialsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            initialsLabel.widthAnchor.constraint(equalToConstant: 40), // Increased from 32 to 40
            initialsLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // Product label
            productLabel.leadingAnchor.constraint(equalTo: initialsLabel.trailingAnchor, constant: 6), // Reduced spacing
            productLabel.centerYAnchor.constraint(equalTo: initialsLabel.centerYAnchor),
            
            // Quantity label
            quantityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            quantityLabel.centerYAnchor.constraint(equalTo: productLabel.centerYAnchor),
            
            // Time label
            timeLabel.trailingAnchor.constraint(equalTo: quantityLabel.trailingAnchor),
            timeLabel.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 0), // No extra space
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4), // Minimal bottom padding
            
            // Ensure product label doesn’t overlap with quantity
            productLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -3),
            
            // Further reduce cell height
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 42) // Super compact
        ])
    }



    func configure(with item: ViewController.StockItem) {
        productLabel.text = item.productName
        quantityLabel.text = "+\(Int(item.quantity))"  // Adds a '+' sign
        
        // Format the timestamp
        if let createdAt = item.createdAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

            if let date = dateFormatter.date(from: createdAt) {
                let calendar = Calendar.current
                
                if calendar.isDateInToday(date) {
                    timeLabel.text = "Today, \(formatTime(date: date))"
                } else if calendar.isDateInYesterday(date) {
                    timeLabel.text = "Yesterday, \(formatTime(date: date))"
                } else {
                    // Full date format for older dates
                    dateFormatter.dateFormat = "d MMMM, h:mm a"
                    let dateString = dateFormatter.string(from: date)
                    timeLabel.text = dateString.replacingOccurrences(of: "AM", with: "A.M.")
                                               .replacingOccurrences(of: "PM", with: "P.M.")
                }
            } else {
                timeLabel.text = createdAt  // Fallback to raw string
            }
        } else {
            timeLabel.text = "Just now"
        }

        initialsLabel.text = getInitials(from: item.productName)
    }

    // Helper function to format time (h:mm A.M./P.M.)
    private func formatTime(date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a" // 12-hour format with AM/PM
        return timeFormatter.string(from: date).replacingOccurrences(of: "AM", with: "A.M.")
                                              .replacingOccurrences(of: "PM", with: "P.M.")
    }

    
    private func getInitials(from name: String) -> String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).map { String($0.first ?? Character("")).uppercased() }.joined()
        return initials.isEmpty ? "I" : initials
    }
}

