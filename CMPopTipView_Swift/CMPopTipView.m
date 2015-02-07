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
    return self.t_bubbleFrame;
}

- (CGRect)contentFrame {
	return self.t_contentFrame;
}

- (void)layoutSubviews {
    [self t_layoutSubviews];
}

- (void)drawRect:(__unused CGRect)rect
{
    [self t_drawRect:rect];
}

- (void)presentPointingAtView:(UIView *)targetView inView:(UIView *)containerView animated:(BOOL)animated {
	
    [self t_presentPointingAtView:targetView inView:containerView animated:animated];
    
}

- (void)presentPointingAtBarButtonItem:(UIBarButtonItem *)barButtonItem animated:(BOOL)animated {
    [self t_presentPointingAtBarButtonItem:barButtonItem animated:animated];
}

- (void)finalizeDismiss {
    [self t_finalizeDismiss];
}

- (void)dismissAnimationDidStop:(__unused NSString *)animationID finished:(__unused NSNumber *)finished context:(__unused void *)context
{
	[self finalizeDismiss];
}

- (void)dismissAnimated:(BOOL)animated {
	
    [self t_dismissAnimated:animated];
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

//- (PointDirection) getPointDirection
//{
//  return _pointDirection;
//}

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
