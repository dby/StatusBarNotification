//
//  DBStatusBarNotification.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

enum StatusBarAnimationType {
    case None   /// Notification won't animate
    case Move   /// Notification will move in from the top, and move out again to the top
    case Bounce /// Notification will fall down from the top and bounce a little bit
    case Fade   /// Notification will fade in and fade out
}

enum StatusBarProgressBarPosition {
    case Bottom /// progress bar will be at the bottom of the status bar
    case Center /// progress bar will be at the center of the status bar
    case Top    /// progress bar will be at the top of the status bar
    case Below  /// progress bar will be below the status bar (the prograss bar won't move with the statusbar in this case)
    case NavBar /// progress bar will be below the navigation bar (the prograss bar won't move with the statusbar in this case)
}

/*
 * This class declare the StatusBar's properties
 */
public class StatusBarStyle: NSObject, NSCopying {
    
    internal var barColor: UIColor?     /// The background color of the notification bar
    internal var textColor: UIColor?    /// The text color of the notification label
    internal var textShadow: NSShadow?  /// The text shadow of the notification label
    internal var font: UIFont?          /// The font of the notification label
    internal var textVerticalPositionAdjustment: CGFloat = 0.0 /// A correction of the vertical label position in points. Default is 0.0
    
    internal var animationType: StatusBarAnimationType = .None /// The animation, that is used to present the notification
    
    internal var progressBarColor: UIColor?      /// The background color of the progress bar (on top of the notification bar)
    internal var progressBarHeight:CGFloat = 1.0 /// The height of the progress bar. Default is 1.0
    /// The position of the progress bar. Default is StatusBarProgressBarPositionBottom
    internal var progressBarPosition: StatusBarProgressBarPosition = .Bottom
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        debugPrint("copyWithZone")
        let style: StatusBarStyle = StatusBarStyle()
        style.barColor  = self.barColor
        style.textColor = self.textColor
        style.textShadow = self.textShadow
        style.font = self.font
        style.textVerticalPositionAdjustment = self.textVerticalPositionAdjustment
        style.animationType = self.animationType
        style.progressBarColor  = self.progressBarColor
        style.progressBarHeight = self.progressBarHeight
        style.progressBarPosition = self.progressBarPosition
        return style
    }
    
    public enum StatusBarStyleType: String {
        case Default = "StatusBarStyleDefault"
        case Error   = "StatusBarStyleError"
        case Warning = "StatusBarStyleWarning"
        case Success = "StatusBarStyleSuccess"
        case Matrix  = "StatusBarStyleMatrix"
        case Dark    = "StatusBarStyleDark"
        
        static func allDefaultStyle() -> [StatusBarStyleType] {
            return [Warning, Success, Matrix, Dark, Error, Default]
        }
        
        internal var style: StatusBarStyle {
            let style: StatusBarStyle = StatusBarStyle()
            style.barColor = UIColor.whiteColor()
            style.progressBarColor  = UIColor.greenColor()
            style.progressBarHeight = 1.0
            style.progressBarPosition = .Bottom
            style.textColor = UIColor.grayColor()
            style.font = UIFont.systemFontOfSize(12)
            style.animationType = .Move
            
            switch self {
            case .Default:
                return style
            case .Error:
                style.barColor  = UIColor(red:0.588, green:0.118, blue:0.000, alpha:1.000)
                style.textColor = UIColor.whiteColor()
                style.progressBarColor  = UIColor.redColor()
                style.progressBarHeight = 2.0
                return style
            case .Warning:
                style.barColor  = UIColor(red:0.900, green:0.734, blue:0.034, alpha:1.000)
                style.textColor = UIColor.darkGrayColor()
                style.progressBarColor = style.textColor
                return style
            case .Success:
                style.barColor  = UIColor(red:0.588, green:0.797, blue:0.000, alpha:1.000)
                style.textColor = UIColor.whiteColor()
                style.progressBarColor  = UIColor(red:0.106, green:0.594, blue:0.319, alpha:1.000)
                style.progressBarHeight = 1.0+1.0/UIScreen.mainScreen().scale
                return style
            case .Matrix:
                style.barColor  = UIColor.blackColor()
                style.textColor = UIColor.greenColor()
                style.font =  UIFont(name: "Courier-Bold", size: 14.0)
                style.progressBarColor  = UIColor.greenColor()
                style.progressBarHeight = 2.0
                return style
            case .Dark:
                style.barColor = UIColor.init(red:0.050, green:0.078, blue:0.120, alpha:1.000)
                style.textColor = UIColor.init(white: 0.95, alpha: 1.0)
                style.progressBarHeight = 1.0 + 1.0/UIScreen.mainScreen().scale
                return style
            }
        }
    }
}

/**
 *  This class is a singletion which is used to present notifications
 *  on top of the status bar. To present a notification, use one of the
 *  given class methods.
 */
public class StatusBarNotification: NSObject {

    typealias PrepareStyleBlock = (style: StatusBarStyle?) -> StatusBarStyle
    private var dismissTimer: NSTimer?
    
    private var activeStyle: StatusBarStyle?
    private var defaultStyle: StatusBarStyle?
    private var userStyles: [String : StatusBarStyle] = [:]
   
    private static let singleShareInstance: StatusBarNotification = StatusBarNotification()
    private class func shareInstance() -> StatusBarNotification {
        debugPrint("+shareInstance")
        return singleShareInstance
    }
    
    //MARK:-----Life Cycle-----
    private override init() {
        debugPrint("-init")
        super.init()
        // set defaults
        self.setupDefaultStyles()
        
        // register for orientation changes
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(willChangeStatusBarFrame),
                                                         name: UIApplicationWillChangeStatusBarFrameNotification,
                                                         object: nil)
    }
    
    deinit {
        debugPrint("-deinit")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    ///-----Progress Value-----
    internal var progress: CGFloat = 0.0 {
        willSet {
            debugPrint("property-progress")
            if self.topBar == nil {
                return
            }
            
            // trim progress
            self.progress = min(1.0, max(0.0, newValue))
            
            if (self.progress == 0.0) {
                self.progressView?.frame = CGRectZero
                return;
            }
            
            // update superview
            if (self.activeStyle?.progressBarPosition == .Below || self.activeStyle?.progressBarPosition == .NavBar) {
                self.topBar?.superview?.addSubview(self.progressView!)
            } else {
                self.topBar?.insertSubview(self.progressView!, belowSubview: self.topBar!.textLabel)
            }
            
            // calculate progressView frame
            var frame: CGRect   = self.topBar!.bounds
            var height: CGFloat = min(frame.size.height, 0.5)
            if let _ = self.activeStyle {
                height = min(frame.size.height, max(0.5, self.activeStyle!.progressBarHeight))
            }
            if (height == 20.0 && frame.size.height > height) {
                height = frame.size.height
            }
            frame.size.height = height
            frame.size.width = round(frame.size.width * progress)
            
            // apply y-position from active style
            let barHeight: CGFloat = self.topBar!.bounds.size.height
            if (self.activeStyle?.progressBarPosition == .Bottom) {
                frame.origin.y = barHeight - height
            } else if(self.activeStyle?.progressBarPosition == .Center) {
                frame.origin.y = round((barHeight - height)/2.0)
            } else if(self.activeStyle?.progressBarPosition == .Top) {
                frame.origin.y = 0.0
            } else if(self.activeStyle?.progressBarPosition == .Below) {
                frame.origin.y = barHeight
            } else if(self.activeStyle?.progressBarPosition == .NavBar) {
                var navBarHeight: CGFloat = 44.0
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) {
                    navBarHeight = 32.0
                }
                frame.origin.y = barHeight + navBarHeight
            }
            
            // apply color from active style
            self.progressView?.backgroundColor = self.activeStyle?.progressBarColor
            
            // update progressView frame
            let animated: Bool = !CGRectEqualToRect(self.progressView!.frame, CGRectZero)
            UIView.animateWithDuration(animated ? 0.05 : 0.0, delay: 0, options: .CurveLinear, animations: { 
                self.progressView?.frame = frame
                }, completion: nil)
        }
    }
    
    //MARK:-----Setter Getter-----
    //NOTE:此处不能使用懒加载，懒加载只会执行一次，这次希望的效果是当overlayWindowInstance为nil时，会重新执行；而如果是懒加载，则只会执行一次
    private var overlayWindowInstance: UIWindow?
    private var overlayWindow: UIWindow?  {
        get {
            debugPrint("get-property-overlayWindow")
            if self.overlayWindowInstance == nil {
                
                self.overlayWindowInstance = UIWindow.init(frame: UIScreen.mainScreen().bounds)
                self.overlayWindowInstance!.backgroundColor = UIColor.clearColor()
                self.overlayWindowInstance!.userInteractionEnabled = false
                self.overlayWindowInstance!.windowLevel = UIWindowLevelStatusBar
                self.overlayWindowInstance!.rootViewController = StatusBarNotificationViewController()
                self.overlayWindowInstance!.rootViewController!.view.backgroundColor = UIColor.clearColor()
                
                self.updateWindowTransform()
                self.updateTopBarFrameWithStatusBarFrame(UIApplication.sharedApplication().statusBarFrame)
            }
            return self.overlayWindowInstance
        }
        
        set {
            debugPrint("set-property-overlayWindow")
            self.overlayWindowInstance = newValue
        }
    }
    
    private var topBarInstance: StatusBarView?
    private var topBar: StatusBarView?  {
        get {
            if topBarInstance == nil {
                self.topBarInstance = StatusBarView()
            }
            self.overlayWindow?.rootViewController?.view.addSubview(self.topBarInstance!)
            
            return topBarInstance
        }
        set {
           self.topBarInstance = newValue
        }
    }
    
    private var progressViewInstance: UIView?
    private var progressView: UIView? {
        get {
            if progressViewInstance == nil {
                debugPrint("property-progressView")
                self.progressViewInstance = UIView()
            }
            return self.progressViewInstance
        }
        set {
            self.progressViewInstance = newValue
        }
    }
}

extension StatusBarNotification {
    
    func setupDefaultStyles() {
        debugPrint("-setupDefaultStyles")
        self.defaultStyle = StatusBarStyle.StatusBarStyleType.Default.style
        
        StatusBarStyle.StatusBarStyleType.allDefaultStyle().forEach { (statusBarStyle: StatusBarStyle.StatusBarStyleType) in
            self.userStyles[statusBarStyle.rawValue] = statusBarStyle.style
        }
    }
    
    func addStyleNamed(identifier: String?, prepareBlock: PrepareStyleBlock?) -> String {
        debugPrint("-addStyleNamed")
        assert(identifier != nil, "No identifier provided")
        assert(prepareBlock != nil, "No prepareBlock provided")
        
        let style: StatusBarStyle = self.defaultStyle!.copy() as! StatusBarStyle
        self.userStyles[identifier!] = prepareBlock!(style: style)
        
        return identifier!
    }
    
    //MARK:-----show status-----
    func showWithStatus(status: String?, styleName: String?) -> UIView? {
        debugPrint("-showWithStatus:status:styleName")
        var style: StatusBarStyle?
        if styleName != nil {
            style = self.userStyles[styleName!]
        }
        if style == nil {
            style = self.defaultStyle
        }
        return self.showWithStatus(status, style: style)
    }
    
    func showWithStatus(status: String?, style: StatusBarStyle?) -> UIView? {
        debugPrint("-showWithStatus:status:style")
        // first, check if status bar is visible at all
        if UIApplication.sharedApplication().statusBarHidden {
            return nil
        }
        // prepare for new style
        if style != self.activeStyle {
            self.activeStyle = style
            if self.activeStyle?.animationType == .Fade {
                self.topBar?.alpha = 0
                self.topBar?.transform = CGAffineTransformIdentity
            } else {
                self.topBar?.alpha = 1
                self.topBar?.transform = CGAffineTransformMakeTranslation(0, -(self.topBar!.frame.size.height))
            }
        }
        
        func showActivityIndicator(show:Bool, style:UIActivityIndicatorViewStyle) {
            debugPrint("-showActivityIndicator")
            if (self.topBar == nil){
                return;
            }
            
            if (show) {
                self.topBar?.activityIndicatorView?.startAnimating()
                self.topBar?.activityIndicatorView?.activityIndicatorViewStyle = style
            } else {
                self.topBar?.activityIndicatorView?.stopAnimating()
            }
        }
        
        // cancel previous dismissing & remove animations
        NSRunLoop.currentRunLoop().cancelPerformSelector(#selector(dismiss), target: self, argument: nil)
        self.topBar?.layer.removeAllAnimations()
        
        // create & show window
        self.overlayWindow?.hidden = false
        
        // update style
        self.topBar?.backgroundColor = style?.barColor
        self.topBar?.textVerticalPositionAdjustment = style!.textVerticalPositionAdjustment
        let textLabel: UILabel? = self.topBar?.textLabel
        textLabel?.textColor = style?.textColor
        textLabel?.font = style?.font
        textLabel?.text = status
        textLabel?.accessibilityLabel = status
        
        if ((style?.textShadow) != nil) {
            textLabel?.shadowColor  = style?.textShadow?.shadowColor as? UIColor
            textLabel?.shadowOffset = (style?.textShadow?.shadowOffset)!
        } else {
            textLabel?.shadowColor  = nil
            textLabel?.shadowOffset = CGSizeZero
        }
        
        // reset progress & activity
        self.showActivityIndicator(false, style: .White)
        
        // animate in
        let animationsEnabled: Bool = (style?.animationType != .None)
        if (animationsEnabled && style?.animationType == .Bounce) {
            self.animateInWithBounceAnimation()
        } else {
            UIView.animateWithDuration(animationsEnabled ? 0.4 : 0.0, animations: {
                self.topBar?.alpha = 1.0
                self.topBar?.transform = CGAffineTransformIdentity
            })
        }
        
        return self.topBar
    }
    
    func isVisible() -> Bool {
        debugPrint("-isVisible")
        return (self.topBar != nil)
    }
    
    func showActivityIndicator(show:Bool, style:UIActivityIndicatorViewStyle) {
        debugPrint("-showActivityIndicator")
        if (self.topBar == nil){
            return;
        }
        
        if (show) {
            self.topBar?.activityIndicatorView?.startAnimating()
            self.topBar?.activityIndicatorView?.activityIndicatorViewStyle = style
        } else {
            self.topBar?.activityIndicatorView?.stopAnimating()
        }
    }
    
    //MARK:-----Dismissal-----
    func setDismissTimerWithInterval(interval: NSTimeInterval) {
        debugPrint("-setDismissTimerWithInterval")
        self.dismissTimer?.invalidate()
        
        self.dismissTimer = NSTimer.scheduledTimerWithTimeInterval(interval,
                                                                   target: self,
                                                                   selector: #selector(dismiss),
                                                                   userInfo: nil,
                                                                   repeats: false)
        
        NSRunLoop.currentRunLoop().addTimer(self.dismissTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func dismiss(timer: NSTimer) {
        debugPrint("-dismiss")
        self.dismissAnimated(true)
    }
    
    func dismissAnimated(animated: Bool) {
        debugPrint("-dismissAnimated")
        self.dismissTimer?.invalidate()
        self.dismissTimer = nil
        
        // check animation type
        let animationsEnabled: Bool = (self.activeStyle!.animationType != .None)
        var animatedChanged = false
        if animated && animationsEnabled {
            animatedChanged = true
        }
        let animation: dispatch_block_t =  {
            if (self.activeStyle!.animationType == .Fade) {
                self.topBar?.alpha = 0.0;
            } else {
                self.topBar?.transform = CGAffineTransformMakeTranslation(0, -self.topBar!.frame.size.height)
            }
        }
        
        let complete = { (finished: Bool) in
            self.overlayWindow?.removeFromSuperview()
            self.overlayWindow?.hidden = true
            self.overlayWindow?.rootViewController = nil
            self.overlayWindow = nil
            self.progressView  = nil
            self.topBar = nil
            
        }
        if animatedChanged {
            UIView.animateWithDuration(0.4, animations: animation, completion: complete)
        } else {
            animation()
            complete(true)
        }
    }
}

extension StatusBarNotification {
    
    //MARK:-----Bounce Animation-----
    func animateInWithBounceAnimation() {
        debugPrint("-animateInWithBounceAnimation")
        //don't animate in, if topBar is already fully visible
        if (self.topBar?.frame.origin.y >= 0) {
            return
        }
        
        // easing function (based on github.com/robb/RBBAnimation)
        let RBBEasingFunctionEaseOutBounce = { (t: Float) -> Float in
            if (t < 4.0/11.0) {
                return pow(11.0 / 4.0, 2) * pow(t, 2)
            }
            
            if (t < 8.0/11.0) {
                return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(t - 6.0 / 11.0, 2)
            }
            
            if (t < 10.0 / 11.0) {
                return 15.0 / 16.0 + pow(11.0 / 4.0, 2) * pow(t - 9.0 / 11.0, 2)
            }
            
            return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(t - 21.0 / 22.0, 2)
        }
        
        // create values
        let fromCenterY: Int = -20, toCenterY: Int = 0, animationSteps: Int = 100
        var values = [NSValue]()
        for t in 1...animationSteps {
            
            let easedTime: Float  = RBBEasingFunctionEaseOutBounce((Float(t)*1.0)/Float(animationSteps))
            let easedValue: Float = Float(fromCenterY) + easedTime * (Float(toCenterY) - Float(fromCenterY))
            
            values.append(NSValue.init(CATransform3D: CATransform3DMakeTranslation(0, CGFloat.init(easedValue), 0)))
        }
        
        // build animation
        let animation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform")
        animation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)]
        animation.duration = 0.66
        animation.values   = values
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.delegate = self
        
        self.topBar?.layer.setValue(toCenterY, forKey: animation.keyPath!)
        self.topBar?.layer.addAnimation(animation, forKey: "JDBounceAnimation")
    }
    
    override public func animationDidStop(anim: CAAnimation, finished:Bool) {
        debugPrint("-animationDidStop")
        self.topBar?.transform = CGAffineTransformIdentity
        self.topBar?.layer.removeAllAnimations()
    }
    
    //MARK:-----Rotation Animation-----
    func updateWindowTransform(){
        debugPrint("-updateWindowTransform")
        let window: UIWindow? = UIApplication.sharedApplication().mainApplicationWindowIgnoringWindow(self.overlayWindow!)
        if let _ = window {
            self.overlayWindow?.transform = window!.transform
            self.overlayWindow?.frame = window!.frame
        }
    }
    
    func updateTopBarFrameWithStatusBarFrame(rect: CGRect) {
        debugPrint("-updateTopBarFrameWithStatusBarFrame")
        
        let width  = max(rect.size.width, rect.size.height)
        let height = min(rect.size.width, rect.size.height)
        
        // on ios7 fix position, if statusBar has double height
        var yPos: CGFloat = 0
        if Double(UIDevice.currentDevice().systemVersion) >= 7.0 && height > 20.0 {
            yPos = -height/2.0
        }
        self.topBar!.frame = CGRectMake(0, yPos, width, height)
        
        var style: StatusBarStyle? = self.activeStyle
        if self.activeStyle == nil {
            style = self.defaultStyle!
        }
        if (style!.animationType != .Fade) {
            self.topBar!.transform = CGAffineTransformMakeTranslation(0, -self.topBar!.frame.size.height)
        } else {
            self.topBar!.alpha = 0.0
        }
    }
    
    func willChangeStatusBarFrame(notification: NSNotification) {
        debugPrint("-willChangeStatusBarFrame")
        let newBarFrame: CGRect = (notification.userInfo![UIApplicationStatusBarFrameUserInfoKey]?.CGRectValue())!
        let duration: NSTimeInterval = UIApplication.sharedApplication().statusBarOrientationAnimationDuration
        
        // update window & statusbar
        let updateBlock = {
            self.updateWindowTransform()
            self.updateTopBarFrameWithStatusBarFrame(newBarFrame)
            //            self.progress = self.progress
        };
        
        UIView.animateWithDuration(duration, animations: {
            updateBlock()
        }) { (finished: Bool) in
            // this hack fixes a broken frame after the rotation (#35)
            // but rotation animation is still broken
            updateBlock()
        }
    }
}

extension StatusBarNotification {
    //MARK:-----Presentation-----
    /**
     *  Show a notification. It won't hide automatically,
     *  you have to dimiss it on your own.
     *
     *  @param status The message to display
     *
     *  @return The presented notification view for further customization
     */
    class func showWithStatus(status: String) -> UIView? {
        debugPrint("+showWithStatus:status")
        return self.shareInstance().showWithStatus(status, styleName: nil)
    }
    
    /**
     *  Show a notification with a specific style. It won't
     *  hide automatically, you have to dimiss it on your own.
     *
     *  @param status The message to display
     *  @param styleName The name of the style. You can use any JDStatusBarStyle constant
     *  (JDStatusBarStyleDefault, etc.), or a custom style identifier, after you added a
     *  custom style. If this is nil, the default style will be used.
     *
     *  @return The presented notification view for further customization
     */
    class func showWithStatus(status: String, styleName: String) -> UIView? {
        debugPrint("+showWithStatus:status:styleName")
        return self.shareInstance().showWithStatus(status, styleName: styleName)
    }
    
    /**
     *  Same as showWithStatus:, but the notification will
     *  automatically dismiss after the given timeInterval.
     *
     *  @param status       The message to display
     *  @param timeInterval The duration, how long the notification
     *  is displayed. (Including the animation duration)
     *
     *  @return The presented notification view for further customization
     */
    class func showWithStatus(status: String, timeInterval: NSTimeInterval) -> UIView? {
        debugPrint("+showWithStatus:status:timeInterval")
        let view: UIView? = self.shareInstance().showWithStatus(status, style: nil)
        self.dismissAfter(timeInterval)
        return view
    }
    
    /**
     *  Same as showWithStatus:styleName:, but the notification
     *  will automatically dismiss after the given timeInterval.
     *
     *  @param status       The message to display
     *  @param timeInterval The duration, how long the notification
     *  is displayed. (Including the animation duration)
     *  @param styleName The name of the style. You can use any JDStatusBarStyle constant
     *  (JDStatusBarStyleDefault, etc.), or a custom style identifier, after you added a
     *  custom style. If this is nil, the default style will be used.
     *
     *  @return The presented notification view for further customization
     */
    class func showWithStatus(status: String, timeInterval: NSTimeInterval, styleName: String) -> UIView? {
        debugPrint("+showWithStatus:status:timeInterval:styleName")
        let view: UIView? = self.shareInstance().showWithStatus(status, styleName: styleName)
        self.dismissAfter(timeInterval)
        return view
    }
    
    //MARK:-----Dismissal-----
    /**
     *  Calls dismissAnimated: with animated set to YES
     */
    class func dismiss() {
        debugPrint("+dismiss")
        self.dismissAnimated(true)
    }
    
    /**
     *  Dismisses any currently displayed notification immediately
     *
     *  @param animated If this is YES, the animation style used
     *  for presentation will also be used for the dismissal.
     */
    class func dismissAnimated(animated: Bool) {
        debugPrint("+dismissAnimated")
        StatusBarNotification.shareInstance().dismissAnimated(true)
    }
    
    /**
     *  Same as dismissAnimated:, but you can specify a delay,
     *  so the notification wont be dismissed immediately
     *
     *  @param delay The delay, how long the notification should stay visible
     */
    class func dismissAfter(delay: NSTimeInterval) {
        debugPrint("+dismissAfter")
        StatusBarNotification.shareInstance().setDismissTimerWithInterval(delay)
    }
    
    //Mark:-----Styles-----
    /**
     *  This changes the default style, which is always used
     *  when a method without styleName is used for presentation, or
     *  styleName is nil, or no style is found with this name.
     *
     *  @param prepareBlock A block, which has a JDStatusBarStyle instance as
     *  parameter. This instance can be modified to suit your needs. You need
     *  to return the modified style again.
     */
    class func setDefaultStyle(prepareBlock: PrepareStyleBlock?) {
        
        debugPrint("+setDefaultStyle")
        assert(prepareBlock != nil, "No prepareBlock provided")
        
        let style: StatusBarStyle? = self.shareInstance().defaultStyle?.copy() as? StatusBarStyle
        StatusBarNotification.shareInstance().defaultStyle = prepareBlock!(style: style)
    }
    
    /**
     *  Adds a custom style, which than can be used
     *  in the presentation methods.
     *
     *  @param identifier   The identifier, which will
     *  later be used to reference the configured style.
     *  @param prepareBlock A block, which has a JDStatusBarStyle instance as
     *  parameter. This instance can be modified to suit your needs. You need
     *  to return the modified style again.
     *
     *  @return Returns the given identifier, so it can
     *  be directly used as styleName parameter.
     */
    class func addStyleNamed(identifier: String, prepareBlock:PrepareStyleBlock) -> String {
        debugPrint("+addStyleNamed")
        return StatusBarNotification.shareInstance().addStyleNamed(identifier, prepareBlock:prepareBlock)
    }
    
    //Mark:-----progress & activity-----
    /**
     *  Show the progress below the label.
     *
     *  @param progress Relative progress from 0.0 to 1.0
     */
    class func showProgress(progress: CGFloat) {
        debugPrint("+showProgress")
        return StatusBarNotification.shareInstance().progress = progress
    }
    
    /**
     *  Shows an activity indicator in front of the notification text
     *
     *  @param show  Use this flag to show or hide the activity indicator
     *  @param style Sets the style of the activity indicator
     */
    class func showActivityIndicator(show: Bool, style:UIActivityIndicatorViewStyle) {
        debugPrint("+showActivityIndicator")
        return StatusBarNotification.shareInstance().showActivityIndicator(show, style: style)
    }
    
    //MARK:-----state-----
    /**
     *  This method tests, if a notification is currently displayed.
     *
     *  @return YES, if a notification is currently displayed. Otherwise NO.
     */
    class func isVisible() -> Bool {
        debugPrint("+isVisible")
        return StatusBarNotification.shareInstance().isVisible()
    }
}

extension UIApplication {
    func mainApplicationWindowIgnoringWindow(ignoringWindow: UIWindow?) -> UIWindow? {
        debugPrint("extense+mainApplicationWindowIgnoringWindow")
        for window: UIWindow in UIApplication.sharedApplication().windows {
            if !window.hidden && windows != ignoringWindow {
                return window
            }
        }
        return nil
    }
}