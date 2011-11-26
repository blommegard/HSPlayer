//
//  HSPLayerView.h
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//
//  ARC, AVQueuePlayer -> 4.1?
//  All properties are observable

#import <UIKit/UIKit.h>

@interface HSPlayerView : UIView
@property (nonatomic, strong, readonly) AVPlayer *player;

// Start player by setting the URL (for a start)
@property (nonatomic, copy) NSURL *URL;

- (void)play:(id)sender;
- (void)pause:(id)sender;

@property (nonatomic, assign, getter = isControlsVisible) BOOL controlsVisible;
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;
@end
