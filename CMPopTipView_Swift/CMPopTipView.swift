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
    var titleAlignment:NSTextAlignment = .Center
    
    var textColor:UIColor = UIColor.whiteColor()
    var textFont:UIFont = UIFont.boldSystemFontOfSize(14)
    var textAlignment:NSTextAlignment = .Center
    
    lazy var titleAndMessageAttributedString:NSAttributedString = {
        
        var newString = ""
        var titleRange = NSMakeRange(0, 0)
        var messageRange = NSMakeRange(0, 0)
        if let title = self.title {
            newString = newString + title + "\n"
            titleRange = NSMakeRange(0, newString.characters.count)//NSRangeFromString(title)
        }
        if let message = self.message {
            newString = newString + message
            messageRange = NSMakeRange(titleRange.length, message.characters.count)
        }
        
        let attributedString = NSMutableAttributedString(string: newString)
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = self.titleAlignment
        titleParagraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
        
        let textParagraphStyle = NSMutableParagraphStyle()
        textParagraphStyle.alignment = self.textAlignment
        textParagraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        attributedString.addAttribute(NSFontAttributeName, value: self.titleFont, range: titleRange)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: self.titleColor, range: titleRange)
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: titleParagraphStyle, range: titleRange)
        
        attributedString.addAttribute(NSFontAttributeName, value: self.textFont, range: messageRange)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: self.textColor, range: messageRange)
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: textParagraphStyle, range: messageRange)
        
        return attributedString
    }()
    
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
    
    var targetObject:AnyObject?
    
    // MARK: Private properties
    private var autoDismissTimer:NSTimer?
    private var dismissTarget:UIButton?
    
    private var bubbleSize:CGSize = CGSizeZero
    private var pointDirection:CMPopTipPointDirection?
    private var targetPoint:CGPoint = CGPointZero
    
    private var bubbleFrame:CGRect {
        var bFrame:CGRect!
        if (pointDirection == CMPopTipPointDirection.Up) {
            bFrame = CGRectMake(sidePadding, targetPoint.y+pointerSize, bubbleSize.width, bubbleSize.height);
        } else {
            bFrame = CGRectMake(sidePadding, targetPoint.y-pointerSize-bubbleSize.height, bubbleSize.width, bubbleSize.height);
        }
        return bFrame
    }
    
    private var contentFrame:CGRect {
        let cFrame = self.bubbleFrame.insetBy(dx: cornerRadius, dy: cornerRadius)
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
        
        var pointerSizePlusValue = pointerSize
        if pointDirection == .Down {
            // If the pointer is facing down, we need to minus pointerSize from targetPoint
            // to work out the coordinates of the pointer triangle
            pointerSizePlusValue = -pointerSizePlusValue
        }
        let targetPointA = CGPointMake(targetPoint.x + sidePadding, targetPoint.y)
        let targetPointB = CGPointMake(targetPoint.x + sidePadding + pointerSizePlusValue, targetPoint.y + pointerSizePlusValue)
        let targetPointC = CGPointMake(targetPoint.x + sidePadding - pointerSizePlusValue, targetPoint.y + pointerSizePlusValue)
        
        // These two closures are used whening drawing the bubble rect
        let drawBubbleRectLeftHandSide = { () -> () in
            CGPathAddArcToPoint(bubblePath, nil, bubbleRect.minX, bubbleRect.maxY, bubbleRect.minX, bubbleRect.minY, self.cornerRadius)
            CGPathAddArcToPoint(bubblePath, nil, bubbleRect.minX, bubbleRect.minY, bubbleRect.maxX, bubbleRect.minY, self.cornerRadius)
        }
        let drawBubbleRectRightHandSide = { () -> () in
            CGPathAddArcToPoint(bubblePath, nil, bubbleRect.maxX, bubbleRect.minY, bubbleRect.maxX, bubbleRect.maxY, self.cornerRadius)
            CGPathAddArcToPoint(bubblePath, nil, bubbleRect.maxX, bubbleRect.maxY, bubbleRect.minX, bubbleRect.maxY, self.cornerRadius)
        }
        
        // Bubble
        CGPathMoveToPoint(bubblePath, nil, targetPointA.x, targetPointA.y)
        CGPathAddLineToPoint(bubblePath, nil, targetPointB.x, targetPointB.y)
        
        // Drawing in clockwise direction
        if pointDirection == .Up {
            drawBubbleRectRightHandSide()
            drawBubbleRectLeftHandSide()
        } else {
            drawBubbleRectLeftHandSide()
            drawBubbleRectRightHandSide()
        }
        CGPathAddLineToPoint(bubblePath, nil, targetPointC.x, targetPointC.y)
        
        CGPathCloseSubpath(bubblePath)
        
        CGContextSaveGState(c)
        CGContextAddPath(c, bubblePath)
        CGContextClip(c)
        
        if hasGradientBackground == false{
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
            
            CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint, CGGradientDrawingOptions())
        }
        
        // Draw top hightlight and bottom shadow
        if has3DStyle {
            CGContextSaveGState(c)
            let innerShadowPath = CGPathCreateMutable()
            
            // Add a rectangle larger than the bounds of bubblePath
            CGPathAddRect(innerShadowPath, nil, CGPathGetBoundingBox(bubblePath).insetBy(dx: -30, dy: -30) )
            
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
            CGContextDrawPath(c, .Stroke);
        }
        
        titleAndMessageAttributedString.drawWithRect(contentFrame, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
    }
    
    // MARK: Private - Size calculation methods
    private func titleAndMessageBoundingSize(width width:CGFloat) -> CGSize {
        return titleAndMessageAttributedString.boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).size
    }
    
    // MARK: Presenting methods
    
    func presentPointingAtView(targetView:UIView, inView containerView:UIView, animated:Bool){
        
        if targetObject == nil {
            targetObject = targetView
        }
        
        // If we want to dismiss the bubble when the user taps anywhere, we need to insert
        // an invisible button over the background.
        if dismissTapAnywhere {
            dismissTarget = UIButton(type: .Custom) as UIButton
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
        let maxWidthLimit:CGFloat = containerViewWidth - cornerRadius * 2
        var widthProportion:CGFloat!
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            widthProportion = 1/3
        } else {
            widthProportion = 2/3
        }
        
        if maxWidth > 0 {
            // If "maxWidth" is specified, we need to check to make sure
            // that it's valid, i.e. less than "maxWidthLimit"
            rectWidth = min(maxWidth, maxWidthLimit)
        } else {
            rectWidth = floor(containerViewWidth * widthProportion)
        }
        
        var contentSize = CGSizeZero
        if let customView = customView {
            contentSize = customView.frame.size
        } else {
            contentSize = titleAndMessageBoundingSize(width: rectWidth)
        }
        
        bubbleSize = CGSize(width: contentSize.width + cornerRadius * 2, height: contentSize.height + cornerRadius * 2)
        
        var superview:UIView! = containerView.superview
        assert(superview != nil, "The container view does not have a superview")
        if superview.isKindOfClass(UIWindow.self) {
            superview = containerView
        }
        
        assert(targetView.superview != nil, "The target view does not have a superview")
        let targetRelativeOrigin = targetView.superview!.convertPoint(targetView.frame.origin, toView: superview)
        let containerRelativeOrigin = superview.convertPoint(containerView.frame.origin, toView: superview)
        
        // Y coordinate of pointer target (within containerView)
        var pointerY = CGFloat(0)
        
        if targetRelativeOrigin.y + targetView.bounds.size.height < containerRelativeOrigin.y {
            
            pointDirection = .Up
        } else if targetRelativeOrigin.y > containerRelativeOrigin.y +  containerViewHeight {
            
            pointerY =  containerViewHeight
            pointDirection = .Down
        } else {
            
            pointDirection = preferredPointDirection
            
            let targetOriginInContainer = targetView.convertPoint(CGPointZero, toView: containerView)
            let sizeBelow =  containerViewHeight - targetOriginInContainer.y
            
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
        
        let targetCenterInContainer = targetView.superview!.convertPoint(targetView.center, toView: containerView)
        var targetCenterX = targetCenterInContainer.x
        var finalOriginX = targetCenterX - round(bubbleSize.width * 0.5)
        
        // Making sure "finalOriginX" is within the limits
        finalOriginX = max( finalOriginX, sidePadding )
        finalOriginX = min( finalOriginX, containerViewWidth - bubbleSize.width - sidePadding )
        
        // Making sure "targetCenterX" is within the limits
        targetCenterX = max( targetCenterX, finalOriginX + cornerRadius + pointerSize )
        targetCenterX = min( targetCenterX, finalOriginX + bubbleSize.width - cornerRadius - pointerSize )
        
        let fullHeight = bubbleSize.height + pointerSize + 10
        var finalOriginY = CGFloat(0)
        
        if (pointDirection == .Up) {
            finalOriginY = topMargin + pointerY;
            targetPoint = CGPoint(x: targetCenterX-finalOriginX, y: 0);
        } else {
            finalOriginY = pointerY - fullHeight;
            targetPoint = CGPoint(x: targetCenterX-finalOriginX, y: fullHeight-2.0);
        }
        
        var finalFrame = CGRect(
            x: finalOriginX - sidePadding,
            y: finalOriginY,
            width: bubbleSize.width + sidePadding * 2,
            height: fullHeight
        )
        finalFrame = finalFrame.integral
        
        
        self.transform = CGAffineTransformIdentity
        
        if animated {
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
                
                // Start a little smaller
                self.frame = finalFrame
                self.alpha = 0.5
                self.layer.anchorPoint = CGPointMake(0.5, 0.5)
                transform = CGAffineTransformMakeScale(0.75, 0.75)
                setNeedsDisplay()
                
                // Animate to a bigger size
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
                print("Cannot determine container view from UIBarButtonItem: ", barButtonItem)
                targetObject = nil
                return
            }
        }
        
    }
    
    // MARK: Dismiss
    func dismissAnimated(animated:Bool) {
        if animated {
            var dismissFrame = frame
            dismissFrame.origin.y += 10.0
            
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                
                self.alpha = 0.0
                self.frame = dismissFrame
                
                }, completion: { (completed:Bool) -> Void in
                    
                    self.finalizeDismiss()
            })
            
        } else {
            finalizeDismiss()
        }
    }
    
    func autoDismissAnimated(animated:Bool, atTimeInterval timeInterval:NSTimeInterval) {
        let userInfo = ["animated" : NSNumber(bool: animated)]
        
        autoDismissTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "autoDismissAnimatedDidFire:", userInfo: userInfo, repeats: false)
    }
    
    // MARK: Private: Dimiss
    private func finalizeDismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        
        dismissTarget?.removeFromSuperview()
        dismissTarget = nil
        
        removeFromSuperview()
        
        highlight = false
        targetObject = nil
    }
    
    private func dismissByUser() {
        highlight = true
        setNeedsDisplay()
        dismissAnimated(true)
        notifyDelegatePopTipViewWasDismissedByUser()
    }
    
    private func notifyDelegatePopTipViewWasDismissedByUser() {
        delegate?.popTipViewWasDismissedByUser(self)
    }
    
    // MARK: Dismiss selectors
    func dismissTapAnywhereFired(button:UIButton) {
        dismissByUser()
    }
    
    func autoDismissAnimatedDidFire(theTimer:NSTimer) {
        var shouldAnimate = false
        if let animated = theTimer.userInfo?.objectForKey("animated") as? NSNumber {
            shouldAnimate = animated.boolValue
        }
        dismissAnimated(shouldAnimate)
        notifyDelegatePopTipViewWasDismissedByUser()
    }
    
    // MARK: Handle touches
    // Swift 1.1: use "override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {"
     override func touchesBegan(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if disableTapToDismiss {
            super.touchesBegan(touches!, withEvent: event)
            return
        }
        
        dismissByUser()
    }
    
}
