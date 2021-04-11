//
//  AboutViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 11/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit
import WebKit

class AboutViewController: UIViewController {
    @IBAction func closeButtonAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var aboutTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))

        guard let filepath = Bundle.main.path(forResource: "MyTunaAbout", ofType: "txt")
            else {
                return
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            aboutTextView.text = contents
        } catch {
            print("File Read Error for file \(filepath)")
            return
        }

    }

    @IBAction func dismissButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    //    @objc func doneButtonAction() {
//        dismiss(animated: true, completion: nil)
//    }
}
