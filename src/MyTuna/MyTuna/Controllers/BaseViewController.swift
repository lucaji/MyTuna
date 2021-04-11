//
//  BaseViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 10/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    var isModal: Bool {
        if presentingViewController != nil {
            return true
        }
        if navigationController?.presentingViewController?.presentedViewController === navigationController {
            return true
        }
        if let presentingVC = tabBarController?.presentingViewController, presentingVC is UITabBarController {
            return true
        }
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    
    override func viewWillAppear(_ animated: Bool) {
        // Adapt for iPhone
//        if isModal {
//            let barButton = UIBarButtonItem(title: "Tuner", style: .plain, target: self, action: #selector(modalBackButtonAction(_:)))
//            navigationItem.leftBarButtonItem = barButton
//        }
    }
    
    
    @objc func modalBackButtonAction(_ sender: UIBarButtonItem) { //<- needs `@objc`
        dismiss(animated: true, completion: nil)
    }

    func showAlert(withTitle title:String, andMessage message:String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "OK", style: .default) { (_) -> Void in }
        controller.addAction(actionOk)
        self.present(controller, animated: true, completion: nil)
    }
    
    
    func addTuningTypeAlert(withCompletion completion: @escaping (TuningType) -> Void) {
        let alert = UIAlertController(title: "New Category", message: "Type a new name:", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "New Category"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if let text = textField?.text {
                let ttype = CoreDataStack.singleton.tuningTypeIfExistent(withTitle: text, withDescription:nil)
                CoreDataStack.singleton.saveContext()
                completion(ttype!)
            }
        }))
        self.present(alert, animated: true, completion: nil)

    }
    
    func addInstrumentAlert(withCompletion completion: @escaping (Instrument) -> Void) {
        let alert = UIAlertController(title: "New Instrument", message: "Type a new name:", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "New Instrument"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if let text = textField?.text {
                let instro = CoreDataStack.singleton.instrumentIfExistent(withName: text)
                CoreDataStack.singleton.saveContext()
//                guard let closure = completion else { return }
                completion(instro!)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func renameInstrument(_ instro:Instrument) {
        let alert = UIAlertController(title: "Rename Instrument", message: "Type a new name for \(instro.instrumentName!):", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = instro.instrumentName
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            instro.instrumentName = textField?.text
            CoreDataStack.singleton.saveContext()
        }))
        self.present(alert, animated: true, completion: nil)
        
    }

    func renameTuningType(_ ttype:TuningType) {
        let alert = UIAlertController(title: "Rename Category", message: "Type a new name for \(ttype.tuningTypeName!):", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = ttype.tuningTypeName
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            ttype.tuningTypeName = textField?.text
            CoreDataStack.singleton.saveContext()
        }))
        self.present(alert, animated: true, completion: nil)
        
    }

}

extension BaseViewController : UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
