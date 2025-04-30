//
//  AllInboundsTableViewCell.swift
//  Stokisha
//
//  Created by Ian Omondi on 14/04/2025.
//

import UIKit

class AllInboundsTableViewCell: UITableViewCell {

    static let reuseIdentifier = "AllInboundsTableViewCell"
        
        // MARK: - UI Components
        private let initialsLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 16)
            label.backgroundColor = UIColor(red: 139/255, green: 24/255, blue: 8/255, alpha: 1.0)
            label.layer.cornerRadius = 20
            label.clipsToBounds = true
            return label
        }()
        
        private let productLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            label.textColor = .black
            label.numberOfLines = 1
            return label
        }()
        
        private let quantityLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.textColor = .black
            label.textAlignment = .right
            return label
        }()
        
        private let timeLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            label.textColor = .gray
            label.textAlignment = .right
            return label
        }()
        
        // MARK: - Initialization
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Setup
        private func setupViews() {
            [initialsLabel, productLabel, quantityLabel, timeLabel].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            
            NSLayoutConstraint.activate([
                initialsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                initialsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                initialsLabel.widthAnchor.constraint(equalToConstant: 40),
                initialsLabel.heightAnchor.constraint(equalToConstant: 40),
                
                productLabel.leadingAnchor.constraint(equalTo: initialsLabel.trailingAnchor, constant: 12),
                productLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                productLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -8),
                
                quantityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                quantityLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                
                timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                timeLabel.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 4),
                timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ])
        }
        
        // MARK: - Configuration
        func configure(with inbound: Inbound) {
            productLabel.text = inbound.productName
            quantityLabel.text = "+\(inbound.quantity)"
            initialsLabel.text = getInitials(from: inbound.productName)
            timeLabel.text = formatDate(inbound.createdAt)
        }
        
        private func getInitials(from name: String) -> String {
            let words = name.split(separator: " ")
            let initials = words.prefix(2).map { String($0.first ?? Character("")).uppercased() }.joined()
            return initials.isEmpty ? "I" : initials
        }
        
        private func formatDate(_ dateString: String) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            guard let date = dateFormatter.date(from: dateString) else {
                return dateString
            }
            
            if Calendar.current.isDateInToday(date) {
                return "Today, \(timeFormatter.string(from: date))"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday, \(timeFormatter.string(from: date))"
            } else {
                dateFormatter.dateFormat = "d MMM, h:mm a"
                return dateFormatter.string(from: date)
            }
        }
        
        private lazy var timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter
        }()
}
