//
//  UIApplication+mainWindow.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func mainApplicationWindowIgnoringWindow(ignoringWindow: UIWindow) -> UIWindow? {
        for window: UIWindow in UIApplication.sharedApplication().windows {
            if !window.hidden && windows != ignoringWindow {
                return window
            }
        }
        return nil
    }
}
