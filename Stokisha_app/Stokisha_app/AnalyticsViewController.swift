//
//  AnalyticsViewController.swift
//  Stokisha
//
//  Created by Ian Omondi on 16/04/2025.
//

import UIKit

class AnalyticsViewController: UIViewController {
    
    

    @IBOutlet weak var segmentedPicker: UISegmentedControl!
    @IBOutlet weak var barGraph: UIView!
    
    private var currentPeriod: TimePeriod = .day
    private var salesData: [AnalyticsData] = []
    private var loadingView: UIView?
    
    // Add a date formatter for compact month labels
        private lazy var monthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM" // "Jan", "Feb", etc.
            return formatter
        }()
        
        enum TimePeriod: String {
            case day = "day"
            case week = "week"
            case month = "month"
            case sixMonths = "six_months"
            case year = "year"
            
            var segmentIndex: Int {
                switch self {
                case .day: return 0
                case .week: return 1
                case .month: return 2
                case .sixMonths: return 3
                case .year: return 4
                }
            }
            
            static func from(index: Int) -> TimePeriod? {
                switch index {
                case 0: return .day
                case 1: return .week
                case 2: return .month
                case 3: return .sixMonths
                case 4: return .year
                default: return nil
                }
            }
        }
        
        struct AnalyticsData: Codable {
            let label: String
            let value: Double
        }
        
        struct AnalyticsResponse: Codable {
            let success: Bool
            let period: String?
            let data: [AnalyticsData]
            let error: String?
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            fetchData(for: .day)
        }
        
        private func setupUI() {
            segmentedPicker.removeAllSegments()
            segmentedPicker.insertSegment(withTitle: "D", at: 0, animated: false)
            segmentedPicker.insertSegment(withTitle: "W", at: 1, animated: false)
            segmentedPicker.insertSegment(withTitle: "M", at: 2, animated: false)
            segmentedPicker.insertSegment(withTitle: "6M", at: 3, animated: false)
            segmentedPicker.insertSegment(withTitle: "Y", at: 4, animated: false)
            segmentedPicker.selectedSegmentIndex = TimePeriod.week.segmentIndex
            segmentedPicker.addTarget(self, action: #selector(periodChanged(_:)), for: .valueChanged)
            
            barGraph.backgroundColor = .systemBackground
        }
        
        @objc private func periodChanged(_ sender: UISegmentedControl) {
            guard let period = TimePeriod.from(index: sender.selectedSegmentIndex) else { return }
            currentPeriod = period
            fetchData(for: period)
        }
        
        private func showLoading() {
            // Create a simple loading view programmatically
            let loadingView = UIView(frame: barGraph.bounds)
            loadingView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.center = loadingView.center
            activityIndicator.startAnimating()
            
            loadingView.addSubview(activityIndicator)
            barGraph.addSubview(loadingView)
            
            self.loadingView = loadingView
        }
        
        private func hideLoading() {
            loadingView?.removeFromSuperview()
            loadingView = nil
        }
        
    private func fetchData(for period: TimePeriod) {
        showLoading()
        
        let urlString = "http://127.0.0.1:5000/api/salesanalytics?period=\(period.rawValue)"
        print("Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL")
            hideLoading()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoading()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showError(message: "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.showError(message: "Invalid server response")
                }
                return
            }
            
            print("HTTP Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.showError(message: "Server error: \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showError(message: "No data received")
                }
                return
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(AnalyticsResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if response.success {
                        self.salesData = response.data
                        self.drawBarGraph()
                    } else {
                        self.showError(message: response.error ?? "Server returned error")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError(message: "Failed to decode response: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
        
    private func drawBarGraph() {
            // Clear previous graph
            barGraph.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            guard !salesData.isEmpty else {
                showEmptyState()
                return
            }
            
            let maxValue = salesData.map { $0.value }.max() ?? 1
            let availableHeight = barGraph.bounds.height - 50
            let spacing: CGFloat = 8
            
            // Dynamic bar width based on data count
            let minBarWidth: CGFloat = 8
            let maxBarWidth: CGFloat = 30
            let totalBars = salesData.count
            let availableWidth = barGraph.bounds.width - 40
            let barWidth = min(
                maxBarWidth,
                max(minBarWidth, (availableWidth - CGFloat(totalBars - 1) * spacing) / CGFloat(totalBars))
            )
            
            // Add grid lines
            drawGridLines(maxValue: maxValue, availableHeight: availableHeight)
            
            // Draw each bar
            for (index, dataPoint) in salesData.enumerated() {
                let barHeight = availableHeight * CGFloat(dataPoint.value / maxValue)
                let x = 20 + (barWidth + spacing) * CGFloat(index)
                let y = barGraph.bounds.height - barHeight - 30
                
                // Bar layer
                let barLayer = CALayer()
                barLayer.frame = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                barLayer.backgroundColor = UIColor(red: 0/255, green: 28/255, blue: 45/255, alpha: 1).cgColor
                barLayer.cornerRadius = 4
                barLayer.masksToBounds = true
                barLayer.contentsScale = UIScreen.main.scale
                barGraph.layer.addSublayer(barLayer)
                
                // Value label (above the bar)
                let valueLabel = CATextLayer()
                valueLabel.frame = CGRect(x: x, y: y - 22, width: barWidth, height: 18)
                valueLabel.string = String(format: "%.0f", dataPoint.value)
                valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
                valueLabel.fontSize = 10
                valueLabel.alignmentMode = .center
                valueLabel.foregroundColor = UIColor.label.cgColor
                valueLabel.contentsScale = UIScreen.main.scale
                barGraph.layer.addSublayer(valueLabel)
                
                // Time period label (below the bar)
                let label = CATextLayer()
                label.frame = CGRect(x: x, y: barGraph.bounds.height - 25, width: barWidth, height: 15)
                
                // Format label differently for 6-month view
                if currentPeriod == .sixMonths {
                    label.string = formatCompactLabel(dataPoint.label)
                } else {
                    label.string = dataPoint.label
                }
                
                label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                label.fontSize = 10
                label.alignmentMode = .center
                label.foregroundColor = UIColor.label.cgColor
                label.contentsScale = UIScreen.main.scale
                barGraph.layer.addSublayer(label)
            }
            
            // X-axis line
            let xAxis = CALayer()
            xAxis.frame = CGRect(x: 20, y: barGraph.bounds.height - 30,
                                width: barGraph.bounds.width - 40, height: 1)
            xAxis.backgroundColor = UIColor.systemGray.cgColor
            xAxis.contentsScale = UIScreen.main.scale
            barGraph.layer.addSublayer(xAxis)
        }
        
        /// Formats labels compactly for 6-month view (e.g., "Jan" instead of "January")
        private func formatCompactLabel(_ label: String) -> String {
            // If the label is a date (e.g., "2023-01-01"), parse and format it
            if let date = parseDate(from: label) {
                return monthFormatter.string(from: date)
            }
            // If not a date, return first 3 letters (e.g., "Q1" → "Q1", "Week 1" → "Wee")
            return String(label.prefix(3))
        }
        
        /// Attempts to parse a date from the label (adjust format as needed)
        private func parseDate(from label: String) -> Date? {
            let dateFormats = [
                "yyyy-MM-dd",  // e.g., "2023-01-01"
                "MMM yyyy",     // e.g., "Jan 2023"
                "MMMM yyyy",    // e.g., "January 2023"
            ]
            
            for format in dateFormats {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                if let date = formatter.date(from: label) {
                    return date
                }
            }
            return nil
        }

    
    private func drawGridLines(maxValue: Double, availableHeight: CGFloat) {
        let numberOfHorizontalLines = 5
        let lineColor = UIColor.systemGray.withAlphaComponent(0.3).cgColor
        
        // Horizontal grid lines
        for i in 0..<numberOfHorizontalLines {
            let yPosition = barGraph.bounds.height - 30 - (availableHeight * CGFloat(i) / CGFloat(numberOfHorizontalLines - 1))
            
            let gridLine = CALayer()
            gridLine.frame = CGRect(x: 20, y: yPosition,
                                   width: barGraph.bounds.width - 40, height: 0.5)
            gridLine.backgroundColor = lineColor
            gridLine.contentsScale = UIScreen.main.scale
            barGraph.layer.addSublayer(gridLine)
            
            // Y-axis labels
            let value = maxValue * Double(i) / Double(numberOfHorizontalLines - 1)
            let valueLabel = CATextLayer()
            valueLabel.frame = CGRect(x: 0, y: yPosition - 8, width: 18, height: 16)
            valueLabel.string = String(format: "%.0f", value)
            valueLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
            valueLabel.fontSize = 9
            valueLabel.alignmentMode = .right
            valueLabel.foregroundColor = UIColor.secondaryLabel.cgColor
            valueLabel.contentsScale = UIScreen.main.scale
            barGraph.layer.addSublayer(valueLabel)
        }
        
        // Vertical grid lines (optional)
        if !salesData.isEmpty {
            let barWidth = (barGraph.bounds.width - 40) / CGFloat(salesData.count)
            let spacing: CGFloat = 10
            
            for i in 0...salesData.count {
                let xPosition = 20 + (barWidth + spacing) * CGFloat(i)
                let gridLine = CALayer()
                gridLine.frame = CGRect(x: xPosition, y: barGraph.bounds.height - availableHeight - 30,
                                       width: 0.5, height: availableHeight)
                gridLine.backgroundColor = lineColor
                gridLine.contentsScale = UIScreen.main.scale
                barGraph.layer.addSublayer(gridLine)
            }
        }
    }
    
        private func showEmptyState() {
            let label = UILabel(frame: barGraph.bounds)
            label.text = "No data available"
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            barGraph.addSubview(label)
        }
        
        private func showError(message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}
