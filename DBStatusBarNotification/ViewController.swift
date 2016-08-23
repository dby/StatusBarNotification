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
        
        self.title = "DBStatusBarNotification"
        self.view.addSubview(self.tableView)
        
        self.addCustomStyle()
    }
    
    func addCustomStyle() {
        
        DBStatusBarNotification.addStyleNamed("SBStyle1") { (style) -> DBStatusBarStyle in
            
            style!.barColor  = UIColor.init(red: 0.797, green: 0.000, blue: 0.662, alpha: 1.0)
            style!.textColor = UIColor.whiteColor()
            style!.animationType = .Fade
            style!.font = UIFont.init(name: "SnellRoundhand-Bold", size: 17.0)
            style!.progressBarColor = UIColor.init(red: 0.986, green: 0.062, blue: 0.598, alpha: 1.0)
            style!.progressBarHeight = 20.0
            return style!
        }
        
        DBStatusBarNotification.addStyleNamed("SBStyle2") { (style) -> DBStatusBarStyle in
            
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
        let section1 = ["Show Notification", "DBStatusBarStyleDefault",
                        "Show Progress", "0-100% in 1s",
                        "Show Activity Indicator", "UIActivityIndicatorViewStyleGray",
                        "Dismss Notification", "Animated"]
        
        let section2 = ["Show DBStatusBarStyleError",   "Duration 2s",
                        "Show DBStatusBarStyleWarning", "Duration 2s",
                        "Show DBStatusBarStyleSuccess", "Duration 2s",
                        "Show DBStatusBarStyleDark",    "Duration 2s",
                        "Show DBStatusBarStyleMatrix",  "Duration 2s"]
        
        let section3 = ["show custom style1", "Duration 4s DBStatusBarAnimationTypeFade",
                        "show custom style1", "Duration 4s DBStatusBarAnimationTypeBounce"]
        
        return [section1, section2, section3]
    }()
    
    //MARK:-----Action-----
    @objc private func timerAction() {
        self.progress += 0.1
        DBStatusBarNotification.showProgress(self.progress)
        
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
                DBStatusBarNotification.showWithStatus("0 0")
            } else if indexPath.row == 1 {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5,
                                                                    target: self,
                                                                    selector: #selector(timerAction),
                                                                    userInfo: nil,
                                                                    repeats: true)
                NSRunLoop.currentRunLoop().addTimer(self.timer!, forMode: NSRunLoopCommonModes)
            } else if indexPath.row == 2 {
                DBStatusBarNotification.showActivityIndicator(true, style: .Gray)
            } else if indexPath.row == 3 {
                DBStatusBarNotification.dismiss()
            }
            
        } else if indexPath.section == 1 {
            var style: String = DBStatusBarStyleError
            if indexPath.row == 1 {
                style = DBStatusBarStyleWarning
            } else if indexPath.row == 2 {
                style = DBStatusBarStyleSuccess
            } else if indexPath.row == 3 {
                style = DBStatusBarStyleDark
            } else if indexPath.row == 4 {
                style = DBStatusBarStyleMatrix
            }
            DBStatusBarNotification.showWithStatus("duration 2s", timeInterval: 2.0, styleName: style)
        } else {
//            self.indicatorStyle = (row==0) ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
            
            let style: String = (indexPath.row == 0) ? "SBStyle1" : "SBStyle2"
            DBStatusBarNotification.showWithStatus("Custom Style", timeInterval: 4.0, styleName: style)
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