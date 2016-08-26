//
//  ViewController.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "StatusBarNotification"
        self.view.addSubview(self.tableView)
        
        self.addCustomStyle()
    }
    
    func addCustomStyle() {
        
        StatusBarNotification.addStyleNamed("SBStyle1") { (style) -> StatusBarStyle in
            
            style!.barColor  = UIColor.init(red: 0.797, green: 0.000, blue: 0.662, alpha: 1.0)
            style!.textColor = UIColor.whiteColor()
            style!.animationType = .Fade
            style!.font = UIFont.init(name: "SnellRoundhand-Bold", size: 17.0)
            style!.progressBarColor = UIColor.init(red: 0.986, green: 0.062, blue: 0.598, alpha: 1.0)
            style!.progressBarHeight = 20.0
            return style!
        }
        
        StatusBarNotification.addStyleNamed("SBStyle2") { (style) -> StatusBarStyle in
            
            style!.barColor =  UIColor.cyanColor()
            style!.textColor = UIColor.init(red: 0.056, green: 0.478, blue: 0.998, alpha: 1.0)
            style!.animationType = .Bounce
            style!.progressBarColor = style!.textColor
            style!.progressBarHeight = 5.0
            style!.progressBarPosition = .Top;
            
            if Double(UIDevice.currentDevice().systemVersion) >= 7.0 {
                style?.font = UIFont.init(name: "DINCondensed-Bold", size: 17.0)
                style?.textVerticalPositionAdjustment = 2.0
            } else {
                style?.font = UIFont.init(name: "DINCondensed-Bold", size: 17.0)
            }
            
            return style!
        }
    }
    
    //MARK:-----Setter Getter-----
    private lazy var progress: CGFloat = 0.0
    private lazy var timer: NSTimer? = nil
    
    private lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: self.view.frame)
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var dataSource: [[String]] = {
        let section1 = ["Show Notification", "StatusBarStyleDefault",
                        "Show Progress", "0-100% in 1s",
                        "Show Activity Indicator", "UIActivityIndicatorViewStyleGray",
                        "Dismss Notification", "Animated"]
        
        let section2 = ["Show StatusBarStyleError",   "Duration 2s",
                        "Show StatusBarStyleWarning", "Duration 2s",
                        "Show StatusBarStyleSuccess", "Duration 2s",
                        "Show StatusBarStyleDark",    "Duration 2s",
                        "Show StatusBarStyleMatrix",  "Duration 2s"]
        
        let section3 = ["show custom style1", "Duration 4s StatusBarAnimationTypeFade",
                        "show custom style2", "Duration 4s StatusBarAnimationTypeBounce"]
        
        return [section1, section2, section3]
    }()
    
    //MARK:-----Action-----
    @objc private func timerAction() {
        self.progress += 0.1
        StatusBarNotification.showProgress(self.progress)
        
        if self.progress > 1.0 {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].count/2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier("ViewControllerIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "ViewControllerIdentifier")
        }
        cell?.textLabel?.text = self.dataSource[indexPath.section][indexPath.row*2]
        cell?.detailTextLabel?.text = self.dataSource[indexPath.section][indexPath.row*2+1]
        
        return cell!
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                StatusBarNotification.showWithStatus("0 0")
            } else if indexPath.row == 1 {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5,
                                                                    target: self,
                                                                    selector: #selector(timerAction),
                                                                    userInfo: nil,
                                                                    repeats: true)
                NSRunLoop.currentRunLoop().addTimer(self.timer!, forMode: NSRunLoopCommonModes)
            } else if indexPath.row == 2 {
                StatusBarNotification.showActivityIndicator(true, style: .Gray)
            } else if indexPath.row == 3 {
                StatusBarNotification.dismiss()
            }
        } else if indexPath.section == 1 {
            var style: String = StatusBarStyle.StatusBarStyleType.Error.rawValue
            if indexPath.row == 1 {
                style = StatusBarStyle.StatusBarStyleType.Warning.rawValue
            } else if indexPath.row == 2 {
                style = StatusBarStyle.StatusBarStyleType.Success.rawValue
            } else if indexPath.row == 3 {
                style = StatusBarStyle.StatusBarStyleType.Dark.rawValue
            } else if indexPath.row == 4 {
                style = StatusBarStyle.StatusBarStyleType.Matrix.rawValue
            }
            StatusBarNotification.showWithStatus("duration 2s", timeInterval: 2.0, styleName: style)
        } else {
//            self.indicatorStyle = (indexPath.row==0) ? .White : .Gray;
            let style: String = (indexPath.row == 0) ? "SBStyle1" : "SBStyle2"
            StatusBarNotification.showWithStatus("Custom Style", timeInterval: 4.0, styleName: style)
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Classify"
        } else if section == 1 {
            return "Style"
        } else {
            return "Custom Style"
        }
    }
}