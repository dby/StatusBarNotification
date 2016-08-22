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
    }
    
    //MARK:-----Setter Getter-----
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
                DBStatusBarNotification.showProgress(0.5)
            } else if indexPath.row == 2 {
                
            } else if indexPath.row == 3 {
                DBStatusBarNotification.dismiss()
            }
            
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                
            } else if indexPath.row == 1 {
                
            } else if indexPath.row == 2 {
                
            } else if indexPath.row == 3 {
                
            } else if indexPath.row == 4 {
                
            }
            
        } else {
            if indexPath.row == 0 {
                
            } else {
                
            }
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