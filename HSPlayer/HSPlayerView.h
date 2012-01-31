//
//  HSPLayerView.h
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//
//  ARC, 4.0 minimum.
//  All properties are observable

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer, AVPlayerLayer;

@interface HSPlayerView : UIView
@property (nonatomic, strong, readonly) AVPlayer *player;
/*
 Use this to set the videoGravity, animatable
 Look in <AVFoundation/AVAnimation.h> for possible values
 Defaults to AVLayerVideoGravityResizeAspect
 */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

// Start player by setting the URL (for a start)
@property (nonatomic, copy) NSURL *URL;

- (void)play:(id)sender;
- (void)pause:(id)sender;

- (BOOL)isPlaying;

@property (nonatomic, assign, getter = isControlsVisible) BOOL controlsVisible;
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;

// Hides statusBar if true, defaults to YES
@property (nonatomic, assign) BOOL fullScreen;
@end
