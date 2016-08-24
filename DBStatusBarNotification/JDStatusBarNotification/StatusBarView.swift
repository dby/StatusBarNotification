//
//  JDStatusBarView.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

class StatusBarView: UIView {

    //MARK:-----Variales-----
    internal var textVerticalPositionAdjustment: CGFloat = 0.0 {
        willSet {
            debugPrint("property-textVerticalPositionAdjustment")
            self.textVerticalPositionAdjustment = newValue
            self.setNeedsLayout()
        }
    }
    
    //MARK:-----Layout-----
    override func layoutSubviews() {
        debugPrint("layoutSubviews")
        super.layoutSubviews()
        // label
        self.textLabel.frame = CGRectMake(0,
                                          1 + self.textVerticalPositionAdjustment,
                                          self.bounds.size.width,
                                          self.bounds.size.height - 1)
        // activity indicator
        if let _ = self.activityIndicatorView {
            let textSize: CGSize = self.currentTextSize()
            var indicatorFrame: CGRect = self.activityIndicatorView!.frame
            indicatorFrame.origin.x = round((self.bounds.size.width - textSize.width) / 2.0) - indicatorFrame.size.width - 8.0
            indicatorFrame.origin.y = ceil(1 + (self.bounds.size.height - indicatorFrame.size.height) / 2.0)
            self.activityIndicatorView!.frame = indicatorFrame
        }
    }
    
    func currentTextSize() -> CGSize {
        debugPrint("-currentTextSize")
        var textSize = CGSizeZero
        // use new sizeWithAttributes: if possible
        let selector: Selector = NSSelectorFromString("sizeWithAttributes:")
        if self.textLabel.text!.respondsToSelector(selector) {
            if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 7, minorVersion: 0, patchVersion: 0)) {
                let attributes: [String : AnyObject] = [NSFontAttributeName: self.textLabel.font]
                textSize = self.textLabel.text!.sizeWithAttributes(attributes)
            }
        }
        // otherwise use old sizeWithFont
        else {
            if !(NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 7, minorVersion: 0, patchVersion: 0))) {
//                textSize = self.textLabel.text!.sizeWithFont(self.textLabel.font)
            }
        }
        return textSize;
    }
    
    //MARK:-----Getter Setter-----
    internal lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.backgroundColor = UIColor.clearColor()
        textLabel.baselineAdjustment = .AlignCenters
        textLabel.textAlignment = .Center
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.clipsToBounds = true
        self.addSubview(textLabel)
        
        return textLabel
    }();
    
    internal lazy var activityIndicatorView: UIActivityIndicatorView? = {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.transform = CGAffineTransformMakeScale(0.7, 0.7)
        self.addSubview(activityIndicatorView)
        
        return activityIndicatorView
    }();
}