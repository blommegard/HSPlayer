//
//  HSPLayerView.m
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//

#import "HSPlayerView.h"

static void *HSPlayerViewPlayerRateObservationContext = &HSPlayerViewPlayerRateObservationContext;
static void *HSPlayerViewPlayerCurrentItemObservationContext = &HSPlayerViewPlayerCurrentItemObservationContext;
static void *HSPlayerViewPlayerItemStatusObservationContext = &HSPlayerViewPlayerItemStatusObservationContext;

@interface HSPlayerView ()
/*
@property (nonatomic, strong) UIView *bottomControlsView;
@property (nonatomic, strong) UIView *topControlsView;
*/
@property (nonatomic, strong, readwrite) AVPlayer *player;
/*
 Use this to set the videoGravity, animatable
 Look in <AVFoundation/AVAnimation.h> for possible values
 Defaults to AVLayerVideoGravityResizeAspect
 */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;

- (void)doneLoadingAsset:(AVURLAsset *)asset withKeys:(NSArray *)keys;
@end

@implementation HSPlayerView

@dynamic player;
@dynamic playerLayer;

@synthesize URL = _URL;
@synthesize playerItem = _playerItem;

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {}
    
    return self;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if (context == HSPlayerViewPlayerItemStatusObservationContext) {
        // Sync buttons
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown: {
                // Fail
                // Sync buttons
            }
            break;
                
            case AVPlayerStatusReadyToPlay: {
                // Get duration
                // Enable GO!
                [self.player play];
            }
                break;
                
            case AVPlayerStatusFailed: {
                //Error
            }
                break;
        }
	}

	else if (context == HSPlayerViewPlayerRateObservationContext) {
        // Sync buttons
	}
    
    // -replaceCurrentItemWithPlayerItem: && new
	else if (context == HSPlayerViewPlayerCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        // Null?
        if (newPlayerItem == (id)[NSNull null]) {
            // Disable
        }
        else {
            // New title
            // Sync buttons
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        }
	}
	else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Properties
#pragma mark Public

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *) [self layer] setPlayer:player];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

- (void)setURL:(NSURL *)URL {
    [self willChangeValueForKey:@"URL"];
    _URL = URL;
    [self didChangeValueForKey:@"URL"];
    
    // Create Asset, and load
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    NSArray *keys = [NSArray arrayWithObjects:@"tracks", @"playable", nil];
    
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
       dispatch_async(dispatch_get_main_queue(), ^{
           
           // Displatch to main queue!
           [self doneLoadingAsset:asset withKeys:keys];
       });
    }];
}

#pragma mark - Private

- (void)doneLoadingAsset:(AVURLAsset *)asset withKeys:(NSArray *)keys {
    
    // Check if all keys is OK
	for (NSString *key in keys) {
		NSError *error = nil;
		AVKeyValueStatus status = [asset statusOfValueForKey:key error:&error];
		if (status == AVKeyValueStatusFailed || status == AVKeyValueStatusCancelled) {
            // Error, error
			return;
		}
	}
    
    if (!asset.playable) {
        // Error
    }
    
    // Remove observer from old playerItem and create new one
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    [self setPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
     
    // Observe status, ok -> play
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:HSPlayerViewPlayerItemStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                          //seekToZeroBeforePlay = YES; 
                                                       }];
    
    //seekToZeroBeforePlay = NO; 

    // Create the player
    if (!self.player) {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        
        // Observe currentItem, catch the -replaceCurrentItemWithPlayerItem:
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:HSPlayerViewPlayerCurrentItemObservationContext];
        
        // Observe rate, play/pause-button?
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:HSPlayerViewPlayerRateObservationContext];
        
    }
    
    // New playerItem?
    if (self.player.currentItem != self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        
        // Sync buttons
    }
    
    // Scrub to start
}

@end
