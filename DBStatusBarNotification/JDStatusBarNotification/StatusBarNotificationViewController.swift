//
//  JDStatusBarNotificationViewController.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

class StatusBarNotificationViewController: UIViewController {

    // rotation
    private lazy var mainController: UIViewController? = {
        debugPrint("property-mainController")
        let mainAppWindow: UIWindow? = UIApplication.sharedApplication().mainApplicationWindowIgnoringWindow(self.view.window)
        var topController: UIViewController? = mainAppWindow?.rootViewController
        
        if mainAppWindow != nil && topController != nil {
            while((topController!.presentedViewController) != nil) {
                topController = topController!.presentedViewController
            }
        }
        return topController
    }()
    
//    override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool {
//        return self.mainController()!.shouldAutorotateToInterfaceOrientation(toInterfaceOrientation)
//    }
    
//    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return [[self mainController] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
//    }
    
    override func shouldAutorotate() -> Bool {
        debugPrint("-shouldAutorotate")
        return (self.mainController?.shouldAutorotate())!
    }
    
//    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
//    - (NSUInteger)supportedInterfaceOrientations {
//    #else
//    - (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    #endif
//    return [[self mainController] supportedInterfaceOrientations];
//    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        debugPrint("-preferredInterfaceOrientationForPresentation")
        return (self.mainController?.preferredInterfaceOrientationForPresentation())!
    }
    
    // statusbar
    func JDUIViewControllerBasedStatusBarAppearanceEnabled() -> Bool {
        debugPrint("-JDUIViewControllerBasedStatusBarAppearanceEnabled")
        var enabled: Bool = false
        var onceToken: dispatch_once_t = 0
    
        dispatch_once(&onceToken) {
            if let info: AnyObject = NSBundle.mainBundle().infoDictionary!["UIViewControllerBasedStatusBarAppearance"] {
                enabled = info.boolValue
            }
        }
    
        return enabled;
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        debugPrint("-preferredStatusBarStyle")
        if JDUIViewControllerBasedStatusBarAppearanceEnabled() {
            return (self.mainController?.preferredStatusBarStyle())!
        }
        return UIApplication.sharedApplication().statusBarStyle
    }
    
    override func prefersStatusBarHidden() -> Bool {
        debugPrint("-prefersStatusBarHidden")
        return false
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        debugPrint("-preferredStatusBarUpdateAnimation")
        if JDUIViewControllerBasedStatusBarAppearanceEnabled() {
            return (self.mainController?.preferredStatusBarUpdateAnimation())!
        }
        return super.preferredStatusBarUpdateAnimation()
    }
}