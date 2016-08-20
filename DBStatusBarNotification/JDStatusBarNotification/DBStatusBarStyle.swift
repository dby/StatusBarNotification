//
//  JDStatusBarStyle.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

let DBStatusBarStyleError: String   = "DBStatusBarStyleError"   /// This style has a red background with a white Helvetica label.
let DBStatusBarStyleWarning: String = "DBStatusBarStyleWarning" /// This style has a yellow background with a gray Helvetica label.
let DBStatusBarStyleSuccess: String = "DBStatusBarStyleSuccess" /// This style has a green background with a white Helvetica label.
let DBStatusBarStyleMatrix: String  = "DBStatusBarStyleMatrix"  /// This style has a black background with a green bold Courier label.
let DBStatusBarStyleDefault: String = "DBStatusBarStyleDefault" /// This style has a white background with a gray Helvetica label.
let DBStatusBarStyleDark: String    = "DBStatusBarStyleDark"    /// This style has a nearly black background with a nearly white Helvetica label.

enum JDStatusBarAnimationType {
    case None   /// Notification won't animate
    case Move   /// Notification will move in from the top, and move out again to the top
    case Bounce /// Notification will fall down from the top and bounce a little bit
    case Fade   /// Notification will fade in and fade out
}

enum JDStatusBarProgressBarPosition {
    case Bottom /// progress bar will be at the bottom of the status bar
    case Center /// progress bar will be at the center of the status bar
    case Top    /// progress bar will be at the top of the status bar
    case Below  /// progress bar will be below the status bar (the prograss bar won't move with the statusbar in this case)
    case NavBar /// progress bar will be below the navigation bar (the prograss bar won't move with the statusbar in this case)
}

class DBStatusBarStyle: NSObject, NSCopying {

    //MARK:-----Variables-----
    /// The background color of the notification bar
    internal var barColor: UIColor?
    
    /// The text color of the notification label
    internal var textColor: UIColor?
    
    /// The text shadow of the notification label
    internal var textShadow: NSShadow?
    
    /// The font of the notification label
    internal var font: UIFont?
    
    /// A correction of the vertical label position in points. Default is 0.0
    internal var textVerticalPositionAdjustment: CGFloat = 0.0
    
    //MARK:-----Animation-----
    /// The animation, that is used to present the notification
    internal var animationType: JDStatusBarAnimationType = .None
    
    //MARK:-----Progress Bar-----
    /// The background color of the progress bar (on top of the notification bar)
    internal var progressBarColor: UIColor?
    
    /// The height of the progress bar. Default is 1.0
    internal var progressBarHeight:CGFloat = 1.0
    
    /// The position of the progress bar. Default is JDStatusBarProgressBarPositionBottom
    internal var progressBarPosition: JDStatusBarProgressBarPosition = .Bottom
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        
        let style: DBStatusBarStyle = self.copyWithZone(zone) as! DBStatusBarStyle
        style.barColor = self.barColor;
        style.textColor = self.textColor;
        style.textShadow = self.textShadow;
        style.font = self.font;
        style.textVerticalPositionAdjustment = self.textVerticalPositionAdjustment;
        style.animationType = self.animationType;
        style.progressBarColor = self.progressBarColor;
        style.progressBarHeight = self.progressBarHeight;
        style.progressBarPosition = self.progressBarPosition;
        return style
    }
    
    class func allDefaultStyleIdentifier() -> [String] {
        return [DBStatusBarStyleError, DBStatusBarStyleWarning, DBStatusBarStyleSuccess, DBStatusBarStyleMatrix, DBStatusBarStyleDark];
    }
    
    class func defaultStyleWithName(styleName: String) -> DBStatusBarStyle
    {
        // setup default style
        let style: DBStatusBarStyle = DBStatusBarStyle()
        style.barColor = UIColor.whiteColor()
        style.progressBarColor = UIColor.greenColor()
        style.progressBarHeight = 1.0
        style.progressBarPosition = .Bottom
        style.textColor = UIColor.grayColor()
        style.font = UIFont.systemFontOfSize(12)
        style.animationType = .Move
    
        // DBStatusBarStyleDefault
        if styleName == DBStatusBarStyleDefault {
            return style;
        }
        // DBStatusBarStyleError
        else if (styleName == DBStatusBarStyleError) {
            style.barColor = UIColor(red:0.588, green:0.118, blue:0.000, alpha:1.000)
            style.textColor = UIColor.whiteColor()
            style.progressBarColor = UIColor.redColor()
            style.progressBarHeight = 2.0
            return style;
        }
        // DBStatusBarStyleWarning
        else if (styleName == DBStatusBarStyleWarning) {
            style.barColor = UIColor(red:0.900, green:0.734, blue:0.034, alpha:1.000)
            style.textColor = UIColor.darkGrayColor()
            style.progressBarColor = style.textColor
            return style;
        }
        // DBStatusBarStyleSuccess
        else if (styleName == DBStatusBarStyleSuccess) {
            style.barColor = UIColor(red:0.588, green:0.797, blue:0.000, alpha:1.000)
            style.textColor = UIColor.whiteColor()
            style.progressBarColor = UIColor(red:0.106, green:0.594, blue:0.319, alpha:1.000)
            style.progressBarHeight = 1.0+1.0/UIScreen.mainScreen().scale
            return style;
        }
        // DBStatusBarStyleDark
        else if (styleName == DBStatusBarStyleDark) {
            style.barColor = UIColor(red:0.050, green:0.078, blue:0.120, alpha:1.000)
            style.textColor = UIColor(white:0.95, alpha:1.0)
            style.progressBarHeight = 1.0+1.0/UIScreen.mainScreen().scale;
            return style;
        }
        // DBStatusBarStyleMatrix
        else if (styleName == DBStatusBarStyleMatrix) {
            style.barColor = UIColor.blackColor()
            style.textColor = UIColor.greenColor()
            style.font = UIFont.systemFontOfSize(14.0) //[UIFont fontWithName:@"Courier-Bold" size:14.0];
            style.progressBarColor = UIColor.greenColor()
            style.progressBarHeight = 2.0
            return style
        }
        return style;
    }
}
