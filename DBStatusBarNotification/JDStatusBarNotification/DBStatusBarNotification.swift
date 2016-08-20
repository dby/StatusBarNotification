//
//  DBStatusBarNotification.swift
//  DBStatusBarNotification
//
//  Created by sys on 16/8/20.
//  Copyright © 2016年 sys. All rights reserved.
//

import UIKit

/**
 *  This class is a singletion which is used to present notifications
 *  on top of the status bar. To present a notification, use one of the
 *  given class methods.
 */
class DBStatusBarNotification: NSObject {

    /**
     *  A block that is used to define the appearance of a notification.
     *  A JDStatusBarStyle instance defines the notification appeareance.
     *
     *  @param style The current default JDStatusBarStyle instance.
     *
     *  @return The modified JDStatusBarStyle instance.
     */
    typealias DBPrepareStyleBlock = (style: DBStatusBarStyle?) -> DBStatusBarStyle
    
    private var dismissTimer: NSTimer?
    
    private var activeStyle: DBStatusBarStyle?
    private var defaultStyle: DBStatusBarStyle?
    private var userStyles: [String : DBStatusBarStyle] = [:]
    
    class func shareInstance() -> DBStatusBarNotification {
        var once: dispatch_once_t = 0
        var sharedInstance: DBStatusBarNotification?
        dispatch_once(&once) {
            sharedInstance = DBStatusBarNotification()
        }
        return sharedInstance!
    }
    
    //MARK:-----Implementation-----
    override init() {
        super.init()
        // set defaults
        self.setupDefaultStyles()
        
        // register for orientation changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(willChangeStatusBarFrame), name: UIApplicationWillChangeStatusBarFrameNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK:-----Custom Styles-----
    func setupDefaultStyles()
    {
        self.defaultStyle = DBStatusBarStyle.defaultStyleWithName(DBStatusBarStyleDefault)
    
        DBStatusBarStyle.allDefaultStyleIdentifier().forEach { (styleName: String) in
            self.userStyles[styleName] = DBStatusBarStyle.defaultStyleWithName(styleName)
        }
    }
    
    func addStyleNamed(identifier: String?, prepareBlock: DBPrepareStyleBlock?) -> String {
        
        assert(identifier != nil, "No identifier provided")
        assert(prepareBlock != nil, "No prepareBlock provided")
        
        let style: DBStatusBarStyle = self.defaultStyle!.copy() as! DBStatusBarStyle
        self.userStyles[identifier!] = prepareBlock!(style: style)
        
        return identifier!
    }
    
    //MARK:-----Presentation-----
    func showWithStatus(status: String?, styleName: String?) -> UIView? {
        var style: DBStatusBarStyle?
        if styleName != nil {
            style = self.userStyles[styleName!]
        }
        if style != nil {
            style = self.defaultStyle
        }
        return self.showWithStatus(status, style: style)
    }
    
    func showWithStatus(status: String?, style: DBStatusBarStyle?) -> UIView? {
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
        textLabel?.accessibilityLabel = status
        textLabel?.text = status
        
        if ((style?.textShadow) != nil) {
            textLabel!.shadowColor = style?.textShadow!.shadowColor as? UIColor
            textLabel!.shadowOffset = (style?.textShadow?.shadowOffset)!
         } else {
            textLabel!.shadowColor = nil
            textLabel!.shadowOffset = CGSizeZero
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
    
    //MARK:-----Dismissal-----
    func setDismissTimerWithInterval(interval: NSTimeInterval)
    {
        self.dismissTimer?.invalidate()
        self.dismissTimer = NSTimer(fireDate: NSDate(timeIntervalSinceReferenceDate: interval),
                                    interval: 0,
                                    target: self,
                                    selector: #selector(dismiss),
                                    userInfo: nil,
                                    repeats: false)
        
        
        NSRunLoop.currentRunLoop().addTimer(self.dismissTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func dismiss(timer: NSTimer) {
        self.dismissAnimated(true)
    }
    
    func dismissAnimated(animated: Bool) {
        self.dismissTimer?.invalidate()
        self.dismissTimer = nil;
    
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
                self.topBar?.transform = CGAffineTransformMakeTranslation(0, -self.topBar!.frame.size.height);
            }
        }
    
        let complete = { (finished: Bool) in
            self.overlayWindow?.removeFromSuperview()
            self.overlayWindow?.hidden = true
            self.overlayWindow?.rootViewController = nil
            self.overlayWindow = nil
            self.progressView = nil
            self.topBar = nil
        }
        if animatedChanged {
            UIView.animateWithDuration(0.4, animations: animation, completion: complete)
        } else {
            animation()
            complete(true)
        }
    }
    
    //MARK:-----Bounce Animation-----
    func animateInWithBounceAnimation()
    {
        //don't animate in, if topBar is already fully visible
        if (self.topBar?.frame.origin.y >= 0) {
            return
        }
    
        // easing function (based on github.com/robb/RBBAnimation)
        let RBBEasingFunctionEaseOutBounce = { (t: Float) -> Float in
            if (t < 4.0/11.0) {
                return pow(11.0/4.0, 2) * pow(t, 2)
            }
            
            if (t < 8.0/11.0) {
                return 3.0/4.0 + pow(11.0/4.0, 2) * pow(t - 6.0/11.0, 2)
            }
            
            if (t < 10.0 / 11.0) {
                return 15.0/16.0 + pow(11.0/4.0, 2) * pow(t - 9.0/11.0, 2)
            }
            
            return 63.0/64.0 + pow(11.0/4.0, 2) * pow(t - 21.0/22.0, 2)
        }
    
        // create values
        let fromCenterY: Int = -20, toCenterY: Int = 0, animationSteps:Int = 100
        var values = [NSValue]()
        for t in 1...animationSteps {
            
            let easedTime: Float  = RBBEasingFunctionEaseOutBounce(Float(t)*1.0)/Float(animationSteps)
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
    
    override func animationDidStop(anim: CAAnimation, finished:Bool) {
        self.topBar!.transform = CGAffineTransformIdentity
        self.topBar?.layer.removeAllAnimations()
    }
    
    //MARK:-----Progress & Activity-----
    internal var progress: CGFloat = 0.0 {
        willSet {
            
            if self.topBar == nil {
                return
            }
            
            // trim progress
            progress = min(1.0, max(0.0,newValue))
            
            if (progress == 0.0) {
                self.progressView?.frame = CGRectZero
                return;
            }
            
            // update superview
            if (self.activeStyle!.progressBarPosition == .Below || self.activeStyle!.progressBarPosition == .NavBar) {
                self.topBar?.superview?.addSubview(self.progressView!)
            } else {
                self.topBar?.insertSubview(self.progressView!, belowSubview: (self.topBar?.textLabel)!)
            }
            
            // calculate progressView frame
            var frame: CGRect = self.topBar!.bounds
            var height: CGFloat = min(frame.size.height, max(0.5, self.activeStyle!.progressBarHeight))
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
    
    func showActivityIndicator(show:Bool, style:UIActivityIndicatorViewStyle) {
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
    
    //MARK:-----State-----
    func isVisible() -> Bool {
        return (self.topBar != nil)
    }
    
    //MARK:-----Setter Getter-----
    private lazy var overlayWindow: UIWindow? = {
        let overlayWindow: UIWindow = UIWindow.init(frame: UIScreen.mainScreen().bounds)
//        overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
        overlayWindow.backgroundColor = UIColor.clearColor()
        overlayWindow.userInteractionEnabled = false
        overlayWindow.windowLevel = UIWindowLevelStatusBar
        overlayWindow.rootViewController = JDStatusBarNotificationViewController()
        overlayWindow.rootViewController!.view.backgroundColor = UIColor.clearColor()
        
//        if !NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 7, minorVersion: 0, patchVersion: 0)) {
//            overlayWindow.rootViewController!.wantsFullScreenLayout = true
//        }
        
        self.updateWindowTransform()
        self.updateTopBarFrameWithStatusBarFrame(UIApplication.sharedApplication().statusBarFrame)
        return overlayWindow
    }()
    
    private lazy var topBar: DBStatusBarView? = {
        
        let topBar: DBStatusBarView = DBStatusBarView()
        self.overlayWindow!.rootViewController!.view.addSubview(topBar)
        
        var style: DBStatusBarStyle = self.activeStyle!
        if self.activeStyle == nil {
            style = self.defaultStyle!
        }
        if (style.animationType != .Fade) {
            self.topBar!.transform = CGAffineTransformMakeTranslation(0, -self.topBar!.frame.size.height);
        } else {
            self.topBar!.alpha = 0.0;
        }
        return topBar
    }()
    
    private lazy var progressView: UIView? = {
        let progressView = UIView()
        return progressView
    }()
    
    //MARK:-----Rotation-----
    func updateWindowTransform(){
        let window: UIWindow = UIApplication.sharedApplication().mainApplicationWindowIgnoringWindow(self.overlayWindow!)!
        overlayWindow?.transform = window.transform
        overlayWindow?.frame = window.frame
    }
    
    func updateTopBarFrameWithStatusBarFrame(rect: CGRect) {
        
        let width: CGFloat = max(rect.size.width, rect.size.height)
        let height: CGFloat = min(rect.size.width, rect.size.height)
    
        // on ios7 fix position, if statusBar has double height
        var yPos: CGFloat = 0
        if /*(UIDevice.currentDevice().systemVersion as String).toInt() >= 7.0 &&*/ height > 20.0 {
            yPos = -height/2.0
        }
        
        self.topBar!.frame = CGRectMake(0, yPos, width, height)
    }
    
    func willChangeStatusBarFrame(notification: NSNotification)
    {
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

extension DBStatusBarNotification {
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
        let view: UIView? = self.shareInstance().showWithStatus(status, styleName: styleName)
        self.dismissAfter(timeInterval)
        return view
    }
    
    //MARK:-----Dismissal-----
    
    /**
     *  Calls dismissAnimated: with animated set to YES
     */
    class func dismiss() {
        self.dismissAnimated(true)
    }
    
    /**
     *  Dismisses any currently displayed notification immediately
     *
     *  @param animated If this is YES, the animation style used
     *  for presentation will also be used for the dismissal.
     */
    class func dismissAnimated(animated: Bool) {
        DBStatusBarNotification.shareInstance().dismissAnimated(true)
    }
    
    /**
     *  Same as dismissAnimated:, but you can specify a delay,
     *  so the notification wont be dismissed immediately
     *
     *  @param delay The delay, how long the notification should stay visible
     */
    class func dismissAfter(delay: NSTimeInterval) {
        DBStatusBarNotification.shareInstance().setDismissTimerWithInterval(delay)
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
    class func setDefaultStyle(prepareBlock: DBPrepareStyleBlock?) {
        
        assert(prepareBlock != nil, "No prepareBlock provided")
        
        let style: DBStatusBarStyle? = self.shareInstance().defaultStyle?.copy() as? DBStatusBarStyle
        DBStatusBarNotification.shareInstance().defaultStyle = prepareBlock!(style: style)
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
    class func addStyleNamed(identifier: String, prepareBlock:DBPrepareStyleBlock) -> String {
        return DBStatusBarNotification.shareInstance().addStyleNamed(identifier, prepareBlock:prepareBlock)
    }
    
    //Mark:-----progress & activity-----
    
    /**
     *  Show the progress below the label.
     *
     *  @param progress Relative progress from 0.0 to 1.0
     */
    class func showProgress(progress: CGFloat) {
        return DBStatusBarNotification.shareInstance().progress = progress
    }
    
    /**
     *  Shows an activity indicator in front of the notification text
     *
     *  @param show  Use this flag to show or hide the activity indicator
     *  @param style Sets the style of the activity indicator
     */
    class func showActivityIndicator(show: Bool, style:UIActivityIndicatorViewStyle) {
        return DBStatusBarNotification.shareInstance().showActivityIndicator(show, style: style)
    }
    
    //MARK:-----state-----
    
    /**
     *  This method tests, if a notification is currently displayed.
     *
     *  @return YES, if a notification is currently displayed. Otherwise NO.
     */
    class func isVisible() -> Bool {
        return DBStatusBarNotification.shareInstance().isVisible()
    }
}