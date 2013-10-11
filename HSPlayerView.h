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

// Start player by setting the URL
@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, assign) BOOL controlsVisible;
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;

// Hides statusBar if true, defaults to YES
@property (nonatomic, assign) BOOL fullScreen;
@end
