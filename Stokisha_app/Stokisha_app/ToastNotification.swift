import UIKit

class ToastNotification {
    static func show(message: String,
                    in view: UIView,
                    duration: TimeInterval = 3.0) {
        
        // Create your custom red color (hex #8B1808)
        let customRed = UIColor(red: 139/255,
                               green: 24/255,
                               blue: 8/255,
                               alpha: 0.9)
        
        let toastContainer = UIView()
        toastContainer.backgroundColor = customRed
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 12
        toastContainer.clipsToBounds = true
        
        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        
        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)
        
        // Constraints and animation code remains the same...
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 12),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -12),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 8),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -8),
            
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            toastContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
}
