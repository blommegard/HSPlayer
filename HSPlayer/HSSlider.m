//
//  HSSlider.m
//  SBSlider
//
//  Created by Simon Blommegård on 2011-11-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HSSlider.h"

@interface HSSlider ()
- (void)setup;
- (float)valueFromTouch:(UITouch *)touch;
@end

@implementation HSSlider
@synthesize value = _value;
@synthesize minimumValue = _minimumValue;
@synthesize maximumValue = _maximumValue;
@synthesize continuous = _continuous;

@synthesize strokeColor = _strokeColor;
@synthesize fillColor = _fillColor;

- (id)init {
    if ((self = [super init]))
        [self setup];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]))
        [self setup];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]))
        [self setup];
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, .5, .5)];

    [self.strokeColor setStroke];
    [path stroke];
    
    CGRect barRect = CGRectInset(self.bounds, 2., 2.);
    CGFloat barWidth = barRect.size.width;
    
    float length = self.maximumValue - self.minimumValue;
    float lenghtValue = self.value - self.minimumValue;
    float percent = lenghtValue / length;
    
    CGFloat width = percent*barWidth;
    
    path = [UIBezierPath bezierPathWithRect:CGRectMake(barRect.origin.x, barRect.origin.y, width, barRect.size.height)];
    
    [self.fillColor setFill];
    [path fill];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL returnValue = [super beginTrackingWithTouch:touch withEvent:event];
    
    [self setValue:[self valueFromTouch:touch]];
    
    if (self.continuous)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return returnValue;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL returnValue = [super continueTrackingWithTouch:touch withEvent:event];
    
    [self setValue:[self valueFromTouch:touch]];
    
    if (self.continuous)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return returnValue;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    [self setValue:[self valueFromTouch:touch]];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self setNeedsDisplay];
}
 
#pragma mark - Properties

- (void)setValue:(float)value {
    if (value > self.maximumValue)
        value = self.maximumValue;
    
    if (value < self.minimumValue)
        value = self.minimumValue;
  
    _value = value;
    
    [self setNeedsDisplay];
}

- (UIColor *)strokeColor {
    if (!_strokeColor)
        _strokeColor = [UIColor whiteColor];
    return _strokeColor;
}

- (UIColor *)fillColor {
    if (!_fillColor)
        _fillColor = [UIColor whiteColor];
    return _fillColor;
}

#pragma mark - Private

- (void)setup {
    [self setMinimumValue:0.];
    [self setMaximumValue:1.];
    [self setValue:.5];
    
    [self setContinuous:YES];
    
    [self setBackgroundColor:[UIColor clearColor]];
}

- (float)valueFromTouch:(UITouch *)touch {
    // Border inset
    CGFloat x = [touch locationInView:self].x-2;
    CGFloat width = self.bounds.size.width-4.;
    CGFloat percent = x / width;
    
    float length = self.maximumValue - self.minimumValue;
    
    return percent*length;
}

@end
