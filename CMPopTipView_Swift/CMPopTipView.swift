/*


CMPopTipView_Swift

Based on the code by:

Chris Miles (chrismiles)



Copyright (c) 2015 Yichi Zhang
https://github.com/yichizhang
zhang-yi-chi@hotmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

import Foundation
import UIKit
import QuartzCore

@objc protocol CMPopTipViewDelegate : NSObjectProtocol {
    func popTipViewWasDismissedByUser(popTipView:CMPopTipView)
}

@objc enum CMPopTipPointDirection : Int {
    case Any = 0
    case Up
    case Down
}

@objc enum CMPopTipAnimation : NSInteger {
    case Slide = 0
    case Pop
}

@objc class CMPopTipView : UIView {
    
    weak var delegate:CMPopTipViewDelegate?
    
    var disableTapToDismiss = false
    var dismissTapAnywhere = false
    
    var borderColor = UIColor.blackColor()
    var bubbleBackgroundColor:UIColor = UIColor(red: 62.0/255.0, green: 60.0/255.0, blue:154.0/255.0, alpha:1.0)
    
    var title:String?
    var message:String?
    var customView:UIView?
    
    var titleColor:UIColor = UIColor.whiteColor()
    var titleFont:UIFont = UIFont.boldSystemFontOfSize(16)
    var textColor:UIColor = UIColor.whiteColor()
    var textFont:UIFont = UIFont.boldSystemFontOfSize(14)
    
    var titleAlignment:NSTextAlignment = .Center
    var textAlignment:NSTextAlignment = .Center
    
    var has3DStyle = true
    var hasShadow:Bool = true {
        didSet {
            if hasShadow {
                layer.shadowOffset = CGSizeMake(0, 3)
                layer.shadowRadius = 2
                layer.shadowColor = UIColor.blackColor().CGColor
                layer.shadowOpacity = 0.3
            } else {
                layer.shadowOpacity = 0
            }
        }
    }
    var highlight = false
    var hasGradientBackground = true
    
    var animation:CMPopTipAnimation = .Slide
    var preferredPointDirection:CMPopTipPointDirection = .Any
    
    var cornerRadius:CGFloat = 10
    var maxWidth:CGFloat = 0

    var sidePadding:CGFloat = 2
    var topMargin:CGFloat = 2
    var pointerSize:CGFloat = 12
    var borderWidth:CGFloat = 1
    
    // Private
    var targetObject:AnyObject? // private set
    var autoDismissTimer:NSTimer?
    var dismissTarget:UIButton?
    
    var bubbleSize:CGSize = CGSizeZero
    var pointDirection:CMPopTipPointDirection?
    var targetPoint:CGPoint = CGPointZero
    
    var bubbleFrame:CGRect {
        var bFrame:CGRect!
        if (pointDirection == CMPopTipPointDirection.Up) {
            bFrame = CGRectMake(sidePadding, targetPoint.y+pointerSize, bubbleSize.width, bubbleSize.height);
        } else {
            bFrame = CGRectMake(sidePadding, targetPoint.y-pointerSize-bubbleSize.height, bubbleSize.width, bubbleSize.height);
        }
        return bFrame
    }
    
    var contentFrame:CGRect {
        let bFrame = self.bubbleFrame
        let cFrame = CGRectMake(
            bFrame.origin.x + cornerRadius,
            bFrame.origin.y + cornerRadius,
            bFrame.size.width - cornerRadius*2,
            bFrame.size.height - cornerRadius*2
        )
        return cFrame
    }
    
    // MARK: Init methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clearColor()
    }
    
    convenience init(title titleToShow:String, message messageToShow:String) {
        self.init(frame: CGRectZero)
        
        title = titleToShow
        message = messageToShow
        
        isAccessibilityElement = true
        accessibilityHint = messageToShow
    }
    
    convenience init(message messageToShow:String) {
        self.init(frame: CGRectZero)
        
        message = messageToShow
        
        isAccessibilityElement = true
        accessibilityHint = messageToShow
    }
    
    convenience init(customView aView:UIView) {
        self.init(frame: CGRectZero)
        
        customView = aView
        addSubview(customView!)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Drawing and layout methods
    
    override func layoutSubviews() {
        self.customView?.frame = contentFrame
    }
    
    override func drawRect(rect:CGRect) {
        
        let bubbleRect = self.bubbleFrame
        
        let c = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(c, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(c, borderWidth)
        
        var bubblePath = CGPathCreateMutable()
        
        let bubbleX = bubbleRect.origin.x; let bubbleY = bubbleRect.origin.y;
        let bubbleWidth = bubbleRect.size.width; let bubbleHeight = bubbleRect.size.height;
        
        if pointDirection == .Up {
            CGPathMoveToPoint(bubblePath, nil, targetPoint.x + sidePadding, targetPoint.y )
            CGPathAddLineToPoint(bubblePath, nil, targetPoint.x + sidePadding + pointerSize, targetPoint.y + pointerSize )
            
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX + bubbleWidth, bubbleY,
                bubbleX + bubbleWidth, bubbleY + cornerRadius,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX + bubbleWidth, bubbleY + bubbleHeight,
                bubbleX + bubbleWidth - cornerRadius, bubbleY + bubbleHeight,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX, bubbleY + bubbleHeight,
                bubbleX, bubbleY + bubbleHeight - cornerRadius,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX, bubbleY,
                bubbleX + cornerRadius, bubbleY,
                cornerRadius
            )
            CGPathAddLineToPoint(bubblePath, nil, targetPoint.x + sidePadding - pointerSize, targetPoint.y + pointerSize)
        } else {
            CGPathMoveToPoint(bubblePath, nil, targetPoint.x + sidePadding, targetPoint.y)
            CGPathAddLineToPoint(bubblePath, nil, targetPoint.x + sidePadding - pointerSize, targetPoint.y - pointerSize)
            
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX, bubbleY + bubbleHeight,
                bubbleX, bubbleY + bubbleHeight - cornerRadius,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX, bubbleY,
                bubbleX + cornerRadius, bubbleY,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX + bubbleWidth, bubbleY,
                bubbleX + bubbleWidth, bubbleY + cornerRadius,
                cornerRadius
            )
            CGPathAddArcToPoint(bubblePath, nil,
                bubbleX + bubbleWidth, bubbleY + bubbleHeight,
                bubbleX + bubbleWidth - cornerRadius, bubbleY + bubbleHeight,
                cornerRadius
            )
            CGPathAddLineToPoint(bubblePath, nil, targetPoint.x + sidePadding + pointerSize, targetPoint.y - pointerSize)
        }
        
        CGPathCloseSubpath(bubblePath)
        
        CGContextSaveGState(c)
        CGContextAddPath(c, bubblePath)
        CGContextClip(c)
        
        if hasGradientBackground {
            // Fill with solid color
            CGContextSetFillColorWithColor(c, bubbleBackgroundColor.CGColor)
            CGContextFillRect(c, bounds)
        } else {
            // Draw clipped background gradient
            let bubbleMiddle = (bubbleY + bubbleHeight * 0.5) / bounds.size.height
            
            let locationCount:size_t = 5
            let locationList:[CGFloat] = [0.0, bubbleMiddle-0.03, bubbleMiddle, bubbleMiddle+0.03, 1.0]
            
            let colorHL:CGFloat = highlight ? 0.25 : 0.0
            
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            var alpha:CGFloat = 0
            let numComponents = CGColorGetNumberOfComponents(bubbleBackgroundColor.CGColor)
            let components = CGColorGetComponents(bubbleBackgroundColor.CGColor)
            
            if (numComponents == 2) {
                red = components[0]
                green = components[0]
                blue = components[0]
                alpha = components[1]
            } else {
                red = components[0]
                green = components[1]
                blue = components[2]
                alpha = components[3]
            }
            
            let colorList:[CGFloat] = [
                //red, green, blue, alpha
                red*1.16+colorHL, green*1.16+colorHL, blue*1.16+colorHL, alpha,
                red*1.16+colorHL, green*1.16+colorHL, blue*1.16+colorHL, alpha,
                red*1.08+colorHL, green*1.08+colorHL, blue*1.08+colorHL, alpha,
                red+colorHL, green+colorHL, blue+colorHL, alpha,
                red+colorHL, green+colorHL, blue+colorHL, alpha
            ]
            
            let myColorSpace = CGColorSpaceCreateDeviceRGB()
            let myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, locationCount)
            
            let startPoint = CGPointMake(0, 0)
            let endPoint = CGPointMake(0, bounds.maxY)
            
            CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint, CGGradientDrawingOptions.allZeros)
        }
        
        // Draw top hightlight and bottom shadow
        if has3DStyle {
            CGContextSaveGState(c)
            let innerShadowPath = CGPathCreateMutable()
            
            // Add a rectangle larger than the bounds of bubblePath
            CGPathAddRect(innerShadowPath, nil, CGPathGetBoundingBox(bubblePath).rectByInsetting(dx: -30, dy: -30) )
            
            // Add bubblePath to innerShadow
            CGPathAddPath(innerShadowPath, nil, bubblePath)
            CGPathCloseSubpath(innerShadowPath)
            
            // Draw top hightlight
            let hightlightColor = UIColor(white: 1.0, alpha: 0.75)
            CGContextSetFillColorWithColor(c, hightlightColor.CGColor)
            CGContextSetShadowWithColor(c, CGSizeMake(0.0, 4.0), 4.0, hightlightColor.CGColor)
            CGContextAddPath(c, innerShadowPath)
            CGContextEOFillPath(c)
            
            // Draw bottom shadow
            let shadowColor = UIColor(white: 0.0, alpha: 0.4)
            CGContextSetFillColorWithColor(c, shadowColor.CGColor)
            CGContextSetShadowWithColor(c, CGSizeMake(0.0, -4.0), 4.0, shadowColor.CGColor)
            CGContextAddPath(c, innerShadowPath)
            CGContextEOFillPath(c)
        }
        
        CGContextRestoreGState(c)
        
        // Draw Border
        if borderWidth > 0 {
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            var alpha:CGFloat = 0
            let numComponents = CGColorGetNumberOfComponents(borderColor.CGColor)
            let components = CGColorGetComponents(borderColor.CGColor)
            
            if (numComponents == 2) {
                red = components[0]
                green = components[0]
                blue = components[0]
                alpha = components[1]
            } else {
                red = components[0]
                green = components[1]
                blue = components[2]
                alpha = components[3]
            }
            
            CGContextSetRGBStrokeColor(c, red, green, blue, alpha);
            CGContextAddPath(c, bubblePath);
            CGContextDrawPath(c, kCGPathStroke);
        }
        
        // Draw title and text
        if let title = title {
            titleColor.set()
            let titleFrame = contentFrame
            
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = titleAlignment
            titleParagraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
            
            // Swift 1.1: use (title as NSString)
            (title as! NSString).drawWithRect(titleFrame, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: titleColor, NSParagraphStyleAttributeName: titleParagraphStyle], context: nil)
        }
        
        if let message = message {
            textColor.set()
            var textFrame = contentFrame
            
            // Move down to make room for title
            textFrame.origin.y += titleBoundingSize(width: textFrame.size.width).height
            
            let textParagraphStyle = NSMutableParagraphStyle()
            textParagraphStyle.alignment = textAlignment
            textParagraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
            
            // Swift 1.1: use (title as NSString)
            (message as! NSString).drawWithRect(textFrame, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: textFont, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: textParagraphStyle], context: nil)
        }
    }

    // MARK: Size calculation methods
    
    func titleBoundingSize(#width:CGFloat) -> CGSize {
        if let title = title {
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
            
            // FIXME: How to pass 'nil' options?
            var titleSize = (title as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleFont, NSParagraphStyleAttributeName: titleParagraphStyle], context: nil).size
            
            return titleSize
        }else {
            return CGSizeZero
        }
    }
    
    func messageBoundingSize(#width:CGFloat) -> CGSize {
        if let message = message {
            
            if !message.isEmpty {
                let textParagraphStyle = NSMutableParagraphStyle()
                textParagraphStyle.alignment = textAlignment
                textParagraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
                
                let textSize = (message as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: textFont, NSParagraphStyleAttributeName: textParagraphStyle], context: nil).size
                
                return textSize
            }
        }
        
        return CGSizeZero
    }
    
    
    // MARK: Presenting methods
    
    func presentPointingAtView(targetView:UIView, inView containerView:UIView, animated:Bool){
    
        if targetObject == nil {
            targetObject = targetView
        }
        
        // If we want to dismiss the bubble when the user taps anywhere, we need to insert
        // an invisible button over the background.
        if dismissTapAnywhere {
            dismissTarget = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
            if let dismissTarget = dismissTarget {
                dismissTarget.addTarget(self, action:"dismissTapAnywhereFired:", forControlEvents: UIControlEvents.TouchUpInside)
                dismissTarget.setTitle("", forState: UIControlState.Normal)
                dismissTarget.frame = containerView.bounds
                containerView.addSubview(dismissTarget)
            }
        }
        
        containerView.addSubview(self)
        
        // Size of rounded rect
        var rectWidth = CGFloat(0)
        let containerViewWidth = containerView.bounds.size.width
		let containerViewHeight = containerView.bounds.size.height
        var j:CGFloat!
        var k:CGFloat!
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            j = 20
            k = 1/3
        } else {
            j = 10
            k = 2/3
        }
        
        if maxWidth > 0 {
            if maxWidth < containerViewWidth {
                rectWidth = maxWidth
            } else {
                rectWidth = containerViewWidth - j
            }
        } else {
            rectWidth = floor(containerViewWidth * k)
        }
        
        var textSize = CGSizeZero
        
        if let message = message {
            
            if !message.isEmpty {
                textSize = messageBoundingSize(width: rectWidth)
            }
        }
        
        if let customView = customView {
            textSize = customView.frame.size
        }
        
        if let title = title {
            
            var titleSize = titleBoundingSize(width: rectWidth)
            
            if titleSize.width > textSize.width {
                textSize.width = titleSize.width
            }
            
            textSize.height += titleSize.height
        }
        
        bubbleSize = CGSize(width: textSize.width + cornerRadius * 2, height: textSize.height + cornerRadius * 2)
        
        var superview:UIView! = containerView.superview
        if superview.isKindOfClass(UIWindow.self) {
            superview = containerView
        }
        
        var targetRelativeOrigin = targetView.superview!.convertPoint(targetView.frame.origin, toView: superview)
        var containerRelativeOrigin = superview.convertPoint(containerView.frame.origin, toView: superview)
        
        // FIXME: Debug println
        println("----")
		println(superview)
		println(targetView.superview!)
		println(containerView)
        println(targetRelativeOrigin)
        println(containerRelativeOrigin)
        println("====")

        // Y coordinate of pointer target (within containerView)
        var pointerY = CGFloat(0)
        
        if targetRelativeOrigin.y + targetView.bounds.size.height < containerRelativeOrigin.y {
            
            pointDirection = .Up
        } else if targetRelativeOrigin.y > containerRelativeOrigin.y +  containerViewHeight {
            
            pointerY =  containerViewHeight
            pointDirection = .Down
        } else {
            
            pointDirection = preferredPointDirection
            
            var targetOriginInContainer = targetView.convertPoint(CGPointZero, toView: containerView)
            var sizeBelow =  containerViewHeight - targetOriginInContainer.y
            
            if pointDirection == .Any {
                
                if sizeBelow > targetOriginInContainer.y {
                    pointDirection = .Up
                } else {
                    pointDirection = .Down
                }
                
            }
            
            if pointDirection == .Down {
                pointerY = targetOriginInContainer.y
            } else {
                pointerY = targetOriginInContainer.y + targetView.bounds.size.height
            }
        }
        
        let p = targetView.superview!.convertPoint(targetView.center, toView: containerView)
        var x_p = p.x
        var x_b = x_p - round(bubbleSize.width * 0.5)
        
        if (x_b < sidePadding) {
            x_b = sidePadding;
        }
        if (x_b + bubbleSize.width + sidePadding > containerViewWidth) {
            x_b = containerViewWidth - bubbleSize.width - sidePadding;
        }
        if (x_p - pointerSize < x_b + cornerRadius) {
            x_p = x_b + cornerRadius + pointerSize;
        }
        if (x_p + pointerSize > x_b + bubbleSize.width - cornerRadius) {
            x_p = x_b + bubbleSize.width - cornerRadius - pointerSize;
        }
        
        let fullHeight = bubbleSize.height + pointerSize + 10
        var y_b = CGFloat(0)
        
        if (pointDirection == .Up) {
            y_b = topMargin + pointerY;
            targetPoint = CGPoint(x: x_p-x_b, y: 0);
        } else {
            y_b = pointerY - fullHeight;
            targetPoint = CGPoint(x: x_p-x_b, y: fullHeight-2.0);
        }
        
        
        
        var finalFrame = CGRect(
            x: x_b - sidePadding,
            y: y_b,
            width: bubbleSize.width + sidePadding * 2,
            height: fullHeight
        )
        finalFrame = finalFrame.integerRect
        
        println("/////")
        println(finalFrame)
        
        if animated{
            if animation == .Slide {
                
                var startFrame = finalFrame
                startFrame.origin.y += 10
                self.frame = startFrame
                self.alpha = 0
                
                setNeedsDisplay()
                
                UIView.animateWithDuration(0.15, animations: { () -> Void in
                    
                    self.alpha = 1.0
                    self.frame = finalFrame
                    
                    }) { (completed:Bool) -> Void in
                        
                }
                
            } else if animation == .Pop {
                
                self.alpha = 0.5
                
                // start a little smaller
                self.frame = finalFrame
                self.layer.anchorPoint = CGPointMake(0.5, 0.5)
                
                transform = CGAffineTransformMakeScale(0.75, 0.75)
                
                setNeedsDisplay()
                
                // animate to a bigger size
                UIView.animateWithDuration(0.15, animations: { () -> Void in
                    
                    self.transform = CGAffineTransformMakeScale(1.1, 1.1)
                    self.alpha = 1.0
                    
                    }) { (completed:Bool) -> Void in
                        
                        UIView.animateWithDuration(0.1, animations: { () -> Void in
                            
                            self.transform = CGAffineTransformIdentity
                            
                            }, completion: { (completed:Bool) -> Void in
                            
                        })
                        
                }
                
            }
        } else {
            
            self.frame = finalFrame
            self.setNeedsDisplay()
        }
        
    }
    
    func presentPointingAtBarButtonItem(barButtonItem:UIBarButtonItem, animated:Bool){
        
        if let targetView = barButtonItem.valueForKey("view") as? UIView {
            let targetSuperview = targetView.superview
            if let containerView = targetSuperview?.superview {
                targetObject = barButtonItem
                presentPointingAtView(targetView, inView: containerView, animated: animated)
            } else {
                println("Cannot determine container view from UIBarButtonItem: ", barButtonItem)
                targetObject = nil
                return
            }
        }
        
    }
    
    // MARK: Dismiss
    
    func finalizeDismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        
        dismissTarget?.removeFromSuperview()
        dismissTarget = nil
        
        removeFromSuperview()
        
        highlight = false
        targetObject = nil
    }
    
    func dismissAnimated(animated:Bool) {
        if animated {
            var dismissFrame = frame
            dismissFrame.origin.y += 10.0
            
            UIView.beginAnimations(nil, context: nil)
            alpha = 0.0
            frame = dismissFrame
            UIView.setAnimationDelegate(self)
            UIView.setAnimationDidStopSelector("dismissAnimationDidStop:finished:context:")
        } else {
            finalizeDismiss()
        }
    }
    
    func dismissByUser() {
        highlight = true
        setNeedsDisplay()
        dismissAnimated(true)
        notifyDelegatePopTipViewWasDismissedByUser()
    }
    
    func dismissTapAnywhereFired(button:UIButton) {
        dismissByUser()
    }
    
    func notifyDelegatePopTipViewWasDismissedByUser() {
        // FIXME: __strong id<CMPopTipViewDelegate> delegate = self.delegate;
        //delegate?.popTipViewWasDismissedByUser(self)
    }
    
    // MARK: NSTimer
    func autoDismissAnimatedDidFire(theTimer:NSTimer) {
        if let animated = theTimer.userInfo?.objectForKey("animated") as? NSNumber {
            dismissAnimated(animated.boolValue)
            notifyDelegatePopTipViewWasDismissedByUser()
        }
    }
    
    func autoDismissAnimated(animated:Bool, atTimeInterval timeInterval:NSTimeInterval) {
        let userInfo = ["animated" : NSNumber(bool: animated)]
        
        autoDismissTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "autoDismissAnimatedDidFire:", userInfo: userInfo, repeats: false)
    }
    
    // Crashes if you write
    // func dismissAnimationDidStop(animationID:String, finished:NSNumber, context:AnyObject) {
    func dismissAnimationDidStop(animationID:NSString, finished:NSNumber, context:AnyObject) {
        finalizeDismiss()
    }
    
    // MARK: Handle touches
    // Swift 1.1: use "override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {"
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if disableTapToDismiss {
            super.touchesBegan(touches, withEvent: event)
            return
        }
        
        dismissByUser()
    }
    
    // MARK: Objective-C Compatibility
    // FIXME: This is not necessary in Swift 1.2
    func setAnimationStyleWithInt(style:Int) {
        if (style == CMPopTipAnimation.Slide.rawValue){
            animation = .Slide
        } else {
            animation = .Pop
        }
    }
}
