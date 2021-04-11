//
//  SplitViewController.swift
//  VoiceMemos
//
//  Created by Zhouqi Mo on 2/20/15.
//  Copyright (c) 2015 Zhouqi Mo. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .allVisible
        preferredPrimaryColumnWidthFraction = 0.5
        maximumPrimaryColumnWidth = 450
        minimumPrimaryColumnWidth = 200
        delegate = self
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}


// MARK: - Split View Controller Delegate

extension SplitViewController: UISplitViewControllerDelegate {
    
    // first hit on ipad
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
        if (svc.displayMode != .primaryHidden && UIDevice.current.userInterfaceIdiom == .phone) {
            return .primaryHidden
        }
        if let secNvc = self.viewControllers.last as? UINavigationController {
            if let tunerVc = secNvc.visibleViewController as? TunerViewController {
                tunerVc.gaugeView?.invalidateNeedle()
            }
        }
        return .automatic
    }
    
    /// gets called first on iPhone
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let navController = secondaryViewController as! UINavigationController
        if let tunerVc = navController.visibleViewController as? TunerViewController {
            if viewControllers.count == 1 {
                if let tabBarController = splitViewController.viewControllers.first as? UITabBarController {
                    tabBarController.viewControllers?.insert(navController, at: 0)
                    tabBarController.selectedIndex = 0
                }
                
            }
            tunerVc.gaugeView?.invalidateNeedle()
            return false
        }
        
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if isCollapsed {
            if let tabBarController = splitViewController.viewControllers.first as? UITabBarController {
                let secondaryNvc = tabBarController.selectedViewController as! UINavigationController
                var viewControllerToPush = vc
                if let nvc = vc as? UINavigationController {
                    viewControllerToPush = nvc.topViewController!
                }
                viewControllerToPush.hidesBottomBarWhenPushed = true
                secondaryNvc.pushViewController(viewControllerToPush, animated: true)
//                if let tunerVc = viewControllerToPush as? TunerViewController {
//                    tunerVc.gaugeView.invalidateNeedle()
//                }
            }
            
            
        } else {
//            self.viewControllers = [self.viewControllers.first!, vc]
        }
        return true
    }
    
//    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
//
//    }
    
    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return orientation == .portrait
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let tabBarController = splitViewController.viewControllers.first as? UITabBarController {
            let navController = tabBarController.selectedViewController as! UINavigationController
            if let noteDetailVc = navController.topViewController as? TuningDetailsViewController {
                return noteDetailVc
            }
//            if let tunerVc = navController.visibleViewController as? TunerViewController {
//                tunerVc.gaugeView.invalidateNeedle()
//            }

        }
        if let primaryNvc = primaryViewController as? UINavigationController {
            return primaryNvc.visibleViewController
        }
        return nil
    }

}

