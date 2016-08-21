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
        
        self.view.addSubview(self.tableView)
    }
    
    //MARK:-----Setter Getter-----
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.frame)
        tableView.delegate   = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var dataSource: [String] = {
        let dataSource = ["1", "2", "3", "4"]
        return dataSource
    }()
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier("ViewControllerIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "ViewControllerIdentifier")
        }
        cell!.textLabel?.text = self.dataSource[indexPath.row]
        
        return cell!
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            DBStatusBarNotification.showWithStatus("afasdfd")
        } else if (indexPath.row == 1) {
            
        }
    }
}