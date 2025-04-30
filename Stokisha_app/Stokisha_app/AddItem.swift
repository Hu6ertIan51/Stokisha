//
//  AddItem.swift
//  Stokisha
//
//  Created by Ian Omondi on 20/03/2025.
//

import UIKit

class AddItem: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSeparatorLine()
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
    
    @IBAction func unwindtoAdd(unwindSegue: UIStoryboardSegue) {
    }

    

}
