//
//  CMPopTipView.m
//
//  Created by Chris Miles on 18/07/10.
//  Copyright (c) Chris Miles 2010-2014.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMPopTipView.h"
#import <QuartzCore/QuartzCore.h>

#import "CMPopTipViewDemo-Swift.h"

@interface CMPopTipView ()
{

}

@end


@implementation CMPopTipView

- (CGRect)bubbleFrame {
	CGRect bubbleFrame;
	if (_pointDirection == PointDirectionUp) {
		bubbleFrame = CGRectMake(_sidePadding, _targetPoint.y+_pointerSize, _bubbleSize.width, _bubbleSize.height);
	}
	else {
		bubbleFrame = CGRectMake(_sidePadding, _targetPoint.y-_pointerSize-_bubbleSize.height, _bubbleSize.width, _bubbleSize.height);
	}
	return bubbleFrame;
}

- (CGRect)contentFrame {
	CGRect bubbleFrame = [self bubbleFrame];
	CGRect contentFrame = CGRectMake(bubbleFrame.origin.x + _cornerRadius,
									 bubbleFrame.origin.y + _cornerRadius,
									 bubbleFrame.size.width - _cornerRadius*2,
									 bubbleFrame.size.height - _cornerRadius*2);
	return contentFrame;
}

- (void)layoutSubviews {
	if (self.customView) {
		
		CGRect contentFrame = [self contentFrame];
        [self.customView setFrame:contentFrame];
    }
}

- (void)drawRect:(__unused CGRect)rect
{
	CGRect bubbleRect = [self bubbleFrame];
	
	CGContextRef c = UIGraphicsGetCurrentContext(); 
    
    CGContextSetRGBStrokeColor(c, 0.0, 0.0, 0.0, 1.0);	// black
	CGContextSetLineWidth(c, self.borderWidth);
    
	CGMutablePathRef bubblePath = CGPathCreateMutable();
	
	if (_pointDirection == PointDirectionUp) {
		CGPathMoveToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding, _targetPoint.y);
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding+_pointerSize, _targetPoint.y+_pointerSize);
		
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y+_cornerRadius,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y+bubbleRect.size.height,
							bubbleRect.origin.x+bubbleRect.size.width-_cornerRadius, bubbleRect.origin.y+bubbleRect.size.height,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x, bubbleRect.origin.y+bubbleRect.size.height,
							bubbleRect.origin.x, bubbleRect.origin.y+bubbleRect.size.height-_cornerRadius,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x, bubbleRect.origin.y,
							bubbleRect.origin.x+_cornerRadius, bubbleRect.origin.y,
							_cornerRadius);
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding-_pointerSize, _targetPoint.y+_pointerSize);
	}
	else {
		CGPathMoveToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding, _targetPoint.y);
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding-_pointerSize, _targetPoint.y-_pointerSize);
		
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x, bubbleRect.origin.y+bubbleRect.size.height,
							bubbleRect.origin.x, bubbleRect.origin.y+bubbleRect.size.height-_cornerRadius,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x, bubbleRect.origin.y,
							bubbleRect.origin.x+_cornerRadius, bubbleRect.origin.y,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y+_cornerRadius,
							_cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL,
							bubbleRect.origin.x+bubbleRect.size.width, bubbleRect.origin.y+bubbleRect.size.height,
							bubbleRect.origin.x+bubbleRect.size.width-_cornerRadius, bubbleRect.origin.y+bubbleRect.size.height,
							_cornerRadius);
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x+_sidePadding+_pointerSize, _targetPoint.y-_pointerSize);
	}
    
	CGPathCloseSubpath(bubblePath);
    
    CGContextSaveGState(c);
	CGContextAddPath(c, bubblePath);
	CGContextClip(c);

    if (self.hasGradientBackground == NO) {
        // Fill with solid color
        CGContextSetFillColorWithColor(c, [self.backgroundColor CGColor]);
        CGContextFillRect(c, self.bounds);
    }
    else {
        // Draw clipped background gradient
        CGFloat bubbleMiddle = (bubbleRect.origin.y+(bubbleRect.size.height/2)) / self.bounds.size.height;
        
        CGGradientRef myGradient;
        CGColorSpaceRef myColorSpace;
        size_t locationCount = 5;
        CGFloat locationList[] = {0.0, bubbleMiddle-0.03, bubbleMiddle, bubbleMiddle+0.03, 1.0};
        
        CGFloat colourHL = 0.0;
        if (_highlight) {
            colourHL = 0.25;
        }
        
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        size_t numComponents = CGColorGetNumberOfComponents([self.backgroundColor CGColor]);
        const CGFloat *components = CGColorGetComponents([self.backgroundColor CGColor]);
        if (numComponents == 2) {
            red = components[0];
            green = components[0];
            blue = components[0];
            alpha = components[1];
        }
        else {
            red = components[0];
            green = components[1];
            blue = components[2];
            alpha = components[3];
        }
        CGFloat colorList[] = {
            //red, green, blue, alpha 
            red*1.16+colourHL, green*1.16+colourHL, blue*1.16+colourHL, alpha,
            red*1.16+colourHL, green*1.16+colourHL, blue*1.16+colourHL, alpha,
            red*1.08+colourHL, green*1.08+colourHL, blue*1.08+colourHL, alpha,
            red     +colourHL, green     +colourHL, blue     +colourHL, alpha,
            red     +colourHL, green     +colourHL, blue     +colourHL, alpha
        };
        myColorSpace = CGColorSpaceCreateDeviceRGB();
        myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, locationCount);
        CGPoint startPoint, endPoint;
        startPoint.x = 0;
        startPoint.y = 0;
        endPoint.x = 0;
        endPoint.y = CGRectGetMaxY(self.bounds);
        
        CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint,0);
        CGGradientRelease(myGradient);
        CGColorSpaceRelease(myColorSpace);
    }
	
    // Draw top highlight and bottom shadow
    if (self.has3DStyle) {
        CGContextSaveGState(c);
        CGMutablePathRef innerShadowPath = CGPathCreateMutable();
        
        // add a rect larger than the bounds of bubblePath
        CGPathAddRect(innerShadowPath, NULL, CGRectInset(CGPathGetPathBoundingBox(bubblePath), -30, -30));
        
        // add bubblePath to innershadow
        CGPathAddPath(innerShadowPath, NULL, bubblePath);
        CGPathCloseSubpath(innerShadowPath);
        
        // draw top highlight
        UIColor *highlightColor = [UIColor colorWithWhite:1.0 alpha:0.75];
        CGContextSetFillColorWithColor(c, highlightColor.CGColor);
        CGContextSetShadowWithColor(c, CGSizeMake(0.0, 4.0), 4.0, highlightColor.CGColor);
        CGContextAddPath(c, innerShadowPath);
        CGContextEOFillPath(c);
        
        // draw bottom shadow
        UIColor *shadowColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        CGContextSetFillColorWithColor(c, shadowColor.CGColor);
        CGContextSetShadowWithColor(c, CGSizeMake(0.0, -4.0), 4.0, shadowColor.CGColor);
        CGContextAddPath(c, innerShadowPath);
        CGContextEOFillPath(c);
        
        CGPathRelease(innerShadowPath);
        CGContextRestoreGState(c);
    }
	
	CGContextRestoreGState(c);

    //Draw Border
    if (self.borderWidth > 0) {
        size_t numBorderComponents = CGColorGetNumberOfComponents([self.borderColor CGColor]);
        const CGFloat *borderComponents = CGColorGetComponents(self.borderColor.CGColor);
        CGFloat r, g, b, a;
        if (numBorderComponents == 2) {
            r = borderComponents[0];
            g = borderComponents[0];
            b = borderComponents[0];
            a = borderComponents[1];
        }
        else {
            r = borderComponents[0];
            g = borderComponents[1];
            b = borderComponents[2];
            a = borderComponents[3];
        }
        
        CGContextSetRGBStrokeColor(c, r, g, b, a);
        CGContextAddPath(c, bubblePath);
        CGContextDrawPath(c, kCGPathStroke);
    }
    
	CGPathRelease(bubblePath);
	
	// Draw title and text
    if (self.title) {
        [self.titleColor set];
        CGRect titleFrame = [self contentFrame];
        
        if ([self.title respondsToSelector:@selector(drawWithRect:options:attributes:context:)]) {
            NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
            titleParagraphStyle.alignment = self.titleAlignment;
            titleParagraphStyle.lineBreakMode = NSLineBreakByClipping;
            
            [self.title drawWithRect:titleFrame
                             options:NSStringDrawingUsesLineFragmentOrigin
                          attributes:@{
                                       NSFontAttributeName: self.titleFont,
                                       NSForegroundColorAttributeName: self.titleColor,
                                       NSParagraphStyleAttributeName: titleParagraphStyle
                                       }
                             context:nil];
            
        }
        else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

            [self.title drawInRect:titleFrame
                          withFont:self.titleFont
                     lineBreakMode:NSLineBreakByClipping
                         alignment:self.titleAlignment];

#pragma clang diagnostic pop

        }
    }
	
	if (self.message) {
		[self.textColor set];
		CGRect textFrame = [self contentFrame];
        
        // Move down to make room for title
        if (self.title) {
            
            if ([self.title respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
                NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
                titleParagraphStyle.lineBreakMode = NSLineBreakByClipping;

                textFrame.origin.y += [self.title boundingRectWithSize:CGSizeMake(textFrame.size.width, 99999.0)
                                                               options:kNilOptions
                                                            attributes:@{
                                                                         NSFontAttributeName: self.titleFont,
                                                                         NSParagraphStyleAttributeName: titleParagraphStyle
                                                                         }
                                                               context:nil].size.height;
            }
            else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

                textFrame.origin.y += [self.title sizeWithFont:self.titleFont
                                             constrainedToSize:CGSizeMake(textFrame.size.width, 99999.0)
                                                 lineBreakMode:NSLineBreakByClipping].height;

#pragma clang diagnostic pop

            }
        }
        
        NSMutableParagraphStyle *textParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        textParagraphStyle.alignment = self.textAlignment;
        textParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        if ([self.message respondsToSelector:@selector(drawWithRect:options:attributes:context:)]) {
            [self.message drawWithRect:textFrame
                               options:NSStringDrawingUsesLineFragmentOrigin attributes:@{
                                                                                          NSFontAttributeName: self.textFont,
                                                                                          NSParagraphStyleAttributeName: textParagraphStyle,
                                                                                          NSForegroundColorAttributeName: self.textColor
                                                                                          }
                               context:nil];
        }
        else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

            [self.message drawInRect:textFrame
                            withFont:self.textFont
                       lineBreakMode:NSLineBreakByWordWrapping
                           alignment:self.textAlignment];

#pragma clang diagnostic pop

        }
    }
}

- (void)presentPointingAtView:(UIView *)targetView inView:(UIView *)containerView animated:(BOOL)animated {
	
    [self t_presentPointingAtView:targetView inView:containerView animated:animated];
    
}

- (void)presentPointingAtBarButtonItem:(UIBarButtonItem *)barButtonItem animated:(BOOL)animated {
	UIView *targetView = (UIView *)[barButtonItem performSelector:@selector(view)];
	UIView *targetSuperview = [targetView superview];
	UIView *containerView = [targetSuperview superview];
	
	if (nil == containerView) {
		NSLog(@"Cannot determine container view from UIBarButtonItem: %@", barButtonItem);
		self.targetObject = nil;
		return;
	}
	
	self.targetObject = barButtonItem;
	
	[self presentPointingAtView:targetView inView:containerView animated:animated];
}

- (void)finaliseDismiss {
	[self.autoDismissTimer invalidate]; self.autoDismissTimer = nil;

    if (self.dismissTarget) {
        [self.dismissTarget removeFromSuperview];
		self.dismissTarget = nil;
    }
	
	[self removeFromSuperview];
    
	_highlight = NO;
	self.targetObject = nil;
}

- (void)dismissAnimationDidStop:(__unused NSString *)animationID finished:(__unused NSNumber *)finished context:(__unused void *)context
{
	[self finaliseDismiss];
}

- (void)dismissAnimated:(BOOL)animated {
	
	if (animated) {
		CGRect frame = self.frame;
		frame.origin.y += 10.0;
		
		[UIView beginAnimations:nil context:nil];
		self.alpha = 0.0;
		self.frame = frame;
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(dismissAnimationDidStop:finished:context:)];
		[UIView commitAnimations];
	}
	else {
		[self finaliseDismiss];
	}
}

- (void)autoDismissAnimatedDidFire:(NSTimer *)theTimer {
    NSNumber *animated = [[theTimer userInfo] objectForKey:@"animated"];
    [self dismissAnimated:[animated boolValue]];
	[self notifyDelegatePopTipViewWasDismissedByUser];
}

- (void)autoDismissAnimated:(BOOL)animated atTimeInterval:(NSTimeInterval)timeInvertal {
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:animated] forKey:@"animated"];
    
    self.autoDismissTimer = [NSTimer scheduledTimerWithTimeInterval:timeInvertal
															 target:self
														   selector:@selector(autoDismissAnimatedDidFire:)
														   userInfo:userInfo
															repeats:NO];
}

- (void)notifyDelegatePopTipViewWasDismissedByUser {
	__strong id<CMPopTipViewDelegate> delegate = self.delegate;
	[delegate popTipViewWasDismissedByUser:self];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.disableTapToDismiss) {
		[super touchesBegan:touches withEvent:event];
		return;
	}

	[self dismissByUser];
}

- (void)dismissTapAnywhereFired:(__unused UIButton *)button
{
	[self dismissByUser];
}

- (void)dismissByUser
{
	_highlight = YES;
	[self setNeedsDisplay];
	
	[self dismissAnimated:YES];
	
	[self notifyDelegatePopTipViewWasDismissedByUser];
}

- (void)popAnimationDidStop:(__unused NSString *)animationID finished:(__unused NSNumber *)finished context:(__unused void *)context
{
    // at the end set to normal size
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.1f];
	self.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		self.opaque = NO;

		_topMargin = 2.0;
		_pointerSize = 12.0;
		_sidePadding = 2.0;
        _borderWidth = 1.0;
		
		self.textFont = [UIFont boldSystemFontOfSize:14.0];
		self.textColor = [UIColor whiteColor];
		self.textAlignment = NSTextAlignmentCenter;
		self.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:60.0/255.0 blue:154.0/255.0 alpha:1.0];
        self.has3DStyle = YES;
        self.borderColor = [UIColor blackColor];
        self.hasShadow = YES;
        self.animation = CMPopTipAnimationSlide;
        self.dismissTapAnywhere = NO;
        self.preferredPointDirection = PointDirectionAny;
        self.hasGradientBackground = YES;
        self.cornerRadius = 10.0;
    }
    return self;
}

- (void)setHasShadow:(BOOL)hasShadow
{
    if (hasShadow != _hasShadow) {
        _hasShadow = hasShadow;

        if (hasShadow) {
            self.layer.shadowOffset = CGSizeMake(0, 3);
            self.layer.shadowRadius = 2.0;
            self.layer.shadowColor = [[UIColor blackColor] CGColor];
            self.layer.shadowOpacity = 0.3;
        } else {
            self.layer.shadowOpacity = 0.0;
        }
    }
}

- (PointDirection) getPointDirection
{
  return _pointDirection;
}

- (id)initWithTitle:(NSString *)titleToShow message:(NSString *)messageToShow
{
	CGRect frame = CGRectZero;
	
	if ((self = [self initWithFrame:frame])) {
        self.title = titleToShow;
		self.message = messageToShow;
        
        self.titleFont = [UIFont boldSystemFontOfSize:16.0];
        self.titleColor = [UIColor whiteColor];
        self.titleAlignment = NSTextAlignmentCenter;
        self.textFont = [UIFont systemFontOfSize:14.0];
		self.textColor = [UIColor whiteColor];
	}
	return self;
}

- (id)initWithMessage:(NSString *)messageToShow
{
	CGRect frame = CGRectZero;
	
	if ((self = [self initWithFrame:frame])) {
		self.message = messageToShow;
        self.isAccessibilityElement = YES;
        self.accessibilityHint = messageToShow;
	}
	return self;
}

- (id)initWithCustomView:(UIView *)aView
{
	CGRect frame = CGRectZero;
	
	if ((self = [self initWithFrame:frame])) {
		self.customView = aView;
        [self addSubview:self.customView];
	}
	return self;
}

@end
