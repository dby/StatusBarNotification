//
//  JDStatusBarNotificationViewController.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

class JDStatusBarNotificationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // rotation
    func mainController() -> UIViewController? {
        let mainAppWindow: UIWindow? = UIApplication.sharedApplication().mainApplicationWindowIgnoringWindow(self.view.window!)
        var topController: UIViewController? = mainAppWindow?.rootViewController
        
        if mainAppWindow != nil && topController != nil {
            while((topController!.presentedViewController) != nil) {
                topController = topController!.presentedViewController
            }
        }
        return topController
    }
    
    
//    override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool {
//        return self.mainController()!.shouldAutorotateToInterfaceOrientation(toInterfaceOrientation)
//    }
    
//
//    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return [[self mainController] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
//    }
    
    override func shouldAutorotate() -> Bool {
        return (self.mainController()?.shouldAutorotate())!
    }
    
//    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
//    - (NSUInteger)supportedInterfaceOrientations {
//    #else
//    - (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    #endif
//    return [[self mainController] supportedInterfaceOrientations];
//    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return (self.mainController()?.preferredInterfaceOrientationForPresentation())!
    }
    
    // statusbar
    func JDUIViewControllerBasedStatusBarAppearanceEnabled() -> Bool {
        var enabled: Bool = false
        var onceToken: dispatch_once_t = 0
    
        dispatch_once(&onceToken) {
            enabled = (NSBundle.mainBundle().infoDictionary!["UIViewControllerBasedStatusBarAppearance"]?.boolValue)!
        }
    
        return enabled;
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if JDUIViewControllerBasedStatusBarAppearanceEnabled() {
            return (self.mainController()?.preferredStatusBarStyle())!
        }
        return UIApplication.sharedApplication().statusBarStyle
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        if JDUIViewControllerBasedStatusBarAppearanceEnabled() {
            return (self.mainController()?.preferredStatusBarUpdateAnimation())!
        }
        return super.preferredStatusBarUpdateAnimation()
    }
}
