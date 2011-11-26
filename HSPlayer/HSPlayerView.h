//
//  HSPLayerView.h
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//
//  ARC!

#import <UIKit/UIKit.h>

@interface HSPlayerView : UIView
@property (nonatomic, strong, readonly) AVPlayer *player;

// Start player by setting the URL (for a start)
@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@end
