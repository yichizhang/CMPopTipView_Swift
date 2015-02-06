//
//  CMPopTipView.swift
//  CMPopTipViewDemo
//
//  Created by Yichi on 1/02/2015.
//  Copyright (c) 2015 Chris Miles. All rights reserved.
//

import Foundation

extension CMPopTipView {
    
    func t_drawRect(rect:CGRect) {
        
        let bubbleRect = self.bubbleFrame()
        
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
            CGContextSetFillColorWithColor(c, backgroundColor.CGColor)
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
            let numComponents = CGColorGetNumberOfComponents(backgroundColor.CGColor)
            let components = CGColorGetComponents(backgroundColor.CGColor)
            
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
        
    }
    
    func t_presentPointingAtView(targetView:UIView, inView containerView:UIView, animated:Bool){
    
        if targetObject == nil {
            targetObject = targetView
        }
        
        // If we want to dismiss the bubble when the user taps anywhere, we need to insert
        // an invisible button over the background.
        if dismissTapAnywhere {
            dismissTarget = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
            dismissTarget.addTarget(self, action:"dismissTapAnywhereFired:", forControlEvents: UIControlEvents.TouchUpInside)
            dismissTarget.setTitle("", forState: UIControlState.Normal)
            dismissTarget.frame = containerView.bounds
            containerView.addSubview(dismissTarget)
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
                let textParagraphStyle = NSMutableParagraphStyle()
                textParagraphStyle.alignment = textAlignment
                textParagraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
                
                textSize = (message as NSString).boundingRectWithSize(CGSize(width: rectWidth, height: CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: textFont, NSParagraphStyleAttributeName: textParagraphStyle], context: nil).size
            }
        }
        
        if let customView = customView {
            textSize = customView.frame.size
        }
        
        if let title = title {
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
            
            // FIXME: How to pass 'nil' options?
            var titleSize = (title as NSString).boundingRectWithSize(CGSize(width: rectWidth, height: CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleFont, NSParagraphStyleAttributeName: titleParagraphStyle], context: nil).size
            
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
        
        if animated{
            if animation == .Slide {
                alpha = 0
                var startFrame = finalFrame
                startFrame.origin.y += 10
                frame = startFrame
            } else if animation == .Pop {
                frame = finalFrame
                alpha = 0.5
                
                // start a little smaller
                transform = CGAffineTransformMakeScale(0.75, 0.75)
                
                // animate to a bigger size
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDelegate(self)
                UIView.setAnimationDidStopSelector("popAnimationDidStop:finished:context:")
                UIView.setAnimationDuration(0.15)
                
                transform = CGAffineTransformMakeScale(1.1, 1.1)
                alpha = 1.0
                
                UIView.commitAnimations()
            }
            
            setNeedsDisplay()
            
            if animation == .Slide {
                UIView.beginAnimations(nil, context: nil)
                
                alpha = 1.0
                frame = finalFrame
                
                UIView.commitAnimations()
            }
        } else {
            
            setNeedsDisplay()
            frame = finalFrame
        }
        
    }
    
    func t_presentPointingAtBarButtonItem(barButtonItem:UIBarButtonItem, animated:Bool){
        
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
}

extension CGRect {
    
    mutating func cm_offset(# dx:CGFloat){
    
        origin.x += dx
    }
    
    mutating func cm_offset(# dy:CGFloat){
        
        origin.y += dy
    }
    
}