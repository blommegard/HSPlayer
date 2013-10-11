//
//  HSSlider.h
//  SBSlider
//
//  Created by Simon Blommegård on 2011-11-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HSSlider : UIControl
@property (nonatomic, assign) float value; // observable
@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;

@property (nonatomic, assign, getter=isContinuous) BOOL continuous; // defaults to YES

@property (nonatomic, strong) UIColor *strokeColor; // defaults to white
@property (nonatomic, strong) UIColor *fillColor; // defaults to white
@end
