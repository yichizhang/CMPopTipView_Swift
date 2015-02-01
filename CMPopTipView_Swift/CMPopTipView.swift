//
//  CMPopTipView.swift
//  CMPopTipViewDemo
//
//  Created by Yichi on 1/02/2015.
//  Copyright (c) 2015 Chris Miles. All rights reserved.
//

import Foundation

extension CMPopTipView {
    func t_presentPointingAtView(targetView:UIView, inView containerView:UIView, animated:Bool) {
    
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
        let containerViewWidth = containerView.frame.size.width
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
        
    }
}