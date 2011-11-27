//
//  HSPLayerView.m
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//

#import "HSPlayerView.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

// Constants
CGFloat const HSPlayerViewControlsAnimationDelay = .4; // ~ statusbar fade duration

// Contexts for KVO
static void *HSPlayerViewPlayerRateObservationContext = &HSPlayerViewPlayerRateObservationContext;
static void *HSPlayerViewPlayerCurrentItemObservationContext = &HSPlayerViewPlayerCurrentItemObservationContext;
static void *HSPlayerViewPlayerAirPlayVideoActiveObservationContext = &HSPlayerViewPlayerAirPlayVideoActiveObservationContext;
static void *HSPlayerViewPlayerItemStatusObservationContext = &HSPlayerViewPlayerItemStatusObservationContext;
static void *HSPlayerViewPlaterItemDurationObservationContext = &HSPlayerViewPlaterItemDurationObservationContext;
static void *HSPlayerViewPlayerLayerReadyForDisplayObservationContext = &HSPlayerViewPlayerLayerReadyForDisplayObservationContext;

@interface HSPlayerView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong, readwrite) AVPlayer *player;

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, assign) CMTime duration;

@property (nonatomic, strong) id playerTimeObserver;

@property (nonatomic, assign) BOOL seekToZeroBeforePlay;
@property (nonatomic, assign) BOOL readyForDisplayTriggered;

// Array of UIView-subclasses
@property (nonatomic, strong) NSArray *controls;

// Controls
@property (nonatomic, strong) UIView *scrubberControlView;
@property (nonatomic, strong) UIButton *playPauseControlButton;
@property (nonatomic, strong) UIButton *closeControlButton;

// Gesture Recognizers
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapRecognizer;

- (void)doneLoadingAsset:(AVAsset *)asset withKeys:(NSArray *)keys;

- (void)toggleControlsWithRecognizer:(UIGestureRecognizer *)recognizer;
- (void)toggleVideoGravityWithRecognizer:(UIGestureRecognizer *)recognizer;

- (void)playPause:(id)sender;
- (void)syncPlayPauseButton;

// Custom images for controls
@property (nonatomic, strong) UIImage *playImage;
@property (nonatomic, strong) UIImage *pauseImage;
@end

@implementation HSPlayerView

@dynamic player;
@dynamic playerLayer;

@synthesize asset = _asset;
@synthesize URL = _URL;
@synthesize playerItem = _playerItem;
@dynamic duration;

@synthesize playerTimeObserver = _playerTimeObserver;

@synthesize seekToZeroBeforePlay = _seekToZeroBeforePlay;
@synthesize readyForDisplayTriggered = _readyForDisplayTriggered;

@synthesize controlsVisible = _controlsVisible;

@synthesize controls = _controls;
@synthesize scrubberControlView = _scrubberControlView;
@synthesize playPauseControlButton = _playPauseControlButton;
@synthesize closeControlButton = _closeControlButton;

@synthesize singleTapRecognizer = _singleTapRecognizer;
@synthesize doubleTapRecognizer = _doubleTapRecognizer;

@synthesize playImage = _playImage;
@synthesize pauseImage = _pauseImage;

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self.playerLayer setOpacity:0];
        [self.playerLayer addObserver:self
                           forKeyPath:@"readyForDisplay"
                              options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                              context:HSPlayerViewPlayerLayerReadyForDisplayObservationContext];
        
        [self addGestureRecognizer:self.singleTapRecognizer];
        [self addGestureRecognizer:self.doubleTapRecognizer];
        
        // Add controls
        for (UIView *view in self.controls)
            [self addSubview:view];
        
        [self setControlsVisible:NO];
    }
    
    return self;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if (context == HSPlayerViewPlayerItemStatusObservationContext) {
        [self syncPlayPauseButton];
        
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
                [self play:self];
            }
                break;
                
            case AVPlayerStatusFailed: {
                //Error
            }
                break;
        }
	}

	else if (context == HSPlayerViewPlayerRateObservationContext) {
        [self syncPlayPauseButton];
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
            [self syncPlayPauseButton];
        }
	}
    
    else if (context == HSPlayerViewPlaterItemDurationObservationContext) {
        // Sync scrubber

    }
    
    // Animate in the player layer
    else if (context == HSPlayerViewPlayerLayerReadyForDisplayObservationContext) {
        BOOL ready = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (ready && !self.readyForDisplayTriggered) {
            [self setReadyForDisplayTriggered:YES];
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            [animation setFromValue:[NSNumber numberWithFloat:0.]];
            [animation setToValue:[NSNumber numberWithFloat:1.]];
            [animation setDuration:1.];
            [self.playerLayer addAnimation:animation forKey:nil];
            [self.playerLayer setOpacity:1.];
        }
    }
    
    else if (context == HSPlayerViewPlayerAirPlayVideoActiveObservationContext) {
        // Show airplay-image
    }
    
	else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Properties

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *) [self layer] setPlayer:player];
    
    // Optimize for airplay if possible
    if ([player respondsToSelector:@selector(allowsAirPlayVideo)]) {
        [player setAllowsAirPlayVideo:YES];
        [player setUsesAirPlayVideoWhileAirPlayScreenIsActive:YES];
        
        [player addObserver:self
                 forKeyPath:@"airPlayVideoActive"
                    options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                    context:HSPlayerViewPlayerAirPlayVideoActiveObservationContext];
    }
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

- (void)setURL:(NSURL *)URL {
    [self willChangeValueForKey:@"URL"];
    _URL = URL;
    [self didChangeValueForKey:@"URL"];
    
    // Create Asset, and load
    
    [self setAsset:[AVURLAsset URLAssetWithURL:URL options:nil]];
    NSArray *keys = [NSArray arrayWithObjects:@"tracks", @"playable", nil];
    
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
       dispatch_async(dispatch_get_main_queue(), ^{
           
           // Displatch to main queue!
           [self doneLoadingAsset:self.asset withKeys:keys];
       });
    }];
}

- (CMTime)duration {
    // Pefered in HTTP Live Streaming.
    if ([self.playerItem respondsToSelector:@selector(duration)] && // 4.3
        self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (CMTIME_IS_VALID(self.playerItem.duration))
            return self.playerItem.duration;
    }
    
    else if (CMTIME_IS_VALID(self.player.currentItem.asset.duration))
        return self.player.currentItem.asset.duration;
    
    return kCMTimeInvalid;
}

- (void)setControlsVisible:(BOOL)controlsVisible {
    [self setControlsVisible:controlsVisible animated:NO];
}

- (NSArray *)controls {
    if (!_controls) {
        _controls = [NSArray arrayWithObjects:
                     self.scrubberControlView,
//                     self.closeControlButton,
                     nil];
    }
    
    return _controls;
}

// Controls
- (UIView *)scrubberControlView {
    if (!_scrubberControlView) {
        _scrubberControlView = [[UIView alloc] initWithFrame:CGRectMake(0., self.bounds.size.height-40., self.bounds.size.width, 40.)];
        [_scrubberControlView setBackgroundColor:[UIColor colorWithWhite:0. alpha:.75]];
        [_scrubberControlView setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth)];
        
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        
        // Airplay?
        if ([volumeView respondsToSelector:@selector(showsRouteButton)]) {
            [volumeView setShowsRouteButton:YES];
            [volumeView setShowsVolumeSlider:NO]; // Dont realy need the software volume shit
            
            [volumeView setCenter:CGPointMake(_scrubberControlView.bounds.size.width-40., _scrubberControlView.bounds.size.height/2-10.)]; // Ugly values..
            [volumeView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin)];
            [_scrubberControlView addSubview:volumeView];
        }

        [self.playPauseControlButton setFrame:CGRectMake(10., 10., 20., 20.)];
        [_scrubberControlView addSubview:self.playPauseControlButton];
    }
    
    return _scrubberControlView;
}

- (UIButton *)playPauseControlButton {
    if (!_playPauseControlButton) {
        _playPauseControlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playPauseControlButton setShowsTouchWhenHighlighted:YES];        
        [_playPauseControlButton setImage:self.playImage forState:UIControlStateNormal];
        [_playPauseControlButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playPauseControlButton;
}

- (UIButton *)closeControlButton {
    return _closeControlButton;
}

- (UITapGestureRecognizer *)singleTapRecognizer {
    if (!_singleTapRecognizer) {
        _singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsWithRecognizer:)];
        // We can handle both single and double
        [_singleTapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
        [_singleTapRecognizer setDelegate:self];
    }
    
    return _singleTapRecognizer;
}

- (UITapGestureRecognizer *)doubleTapRecognizer {
    if (!_doubleTapRecognizer) {
        _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoGravityWithRecognizer:)];
        [_doubleTapRecognizer setNumberOfTapsRequired:2];
        [_doubleTapRecognizer setDelegate:self];
    }
    
    return _doubleTapRecognizer;
}

#pragma mark -

- (void)play:(id)sender {
	if (self.seekToZeroBeforePlay)  {
		[self setSeekToZeroBeforePlay:NO];
		[self.player seekToTime:kCMTimeZero];
	}
    
    [self.player play];
	
    // Update buttons
}

- (void)pause:(id)sender {
    [self.player pause];
    
    // Update buttons
}

- (BOOL)isPlaying {
    //	return mRestoreAfterScrubbingRate != 0.f || 
    return (self.player.rate != 0.);
}

- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated {
    [self willChangeValueForKey:@"controlsVisible"];
    _controlsVisible = controlsVisible;
    [self didChangeValueForKey:@"controlsVisible"];
    
    if (controlsVisible)
        for (UIView *view in self.controls)
            [view setHidden:NO];
    
    [UIView animateWithDuration:(animated ? HSPlayerViewControlsAnimationDelay:0.)
                          delay:0.
                        options:(UIViewAnimationCurveEaseInOut)
                     animations:^{
                         for (UIView *view in self.controls)
                             [view setAlpha:(controlsVisible ? 1.:0.)];
                     } completion:^(BOOL finished) {
                         if (!controlsVisible)
                             for (UIView *view in self.controls)
                                 [view setHidden:YES];
                     }];
    
    [[UIApplication sharedApplication] setStatusBarHidden:(!controlsVisible) withAnimation:UIStatusBarAnimationFade];
}

#pragma mark - Private

- (void)doneLoadingAsset:(AVAsset *)asset withKeys:(NSArray *)keys {
    
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
                                                           [self setSeekToZeroBeforePlay:YES]; 
                                                       }];
    
    [self setSeekToZeroBeforePlay:YES];

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
        [self syncPlayPauseButton];
    }
    
    // Scrub to start
}

- (void)toggleControlsWithRecognizer:(UIGestureRecognizer *)recognizer {
    [self setControlsVisible:(!self.controlsVisible) animated:YES];
}

- (void)toggleVideoGravityWithRecognizer:(UIGestureRecognizer *)recognizer {
    if (self.playerLayer.videoGravity == AVLayerVideoGravityResizeAspect)
        [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    else
        [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (void)playPause:(id)sender {
    [self isPlaying] ? [self pause:sender] : [self play:sender];
}

- (void)syncPlayPauseButton {
    [self.playPauseControlButton setImage:([self isPlaying] ? self.pauseImage : self.playImage) forState:UIControlStateNormal];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // We dont want to to hide the controls when we tap em
    for (UIView *view in self.controls)
        if (CGRectContainsPoint(view.frame, [touch locationInView:self]) && self.controlsVisible)
            return NO;

    return YES;
}

#pragma mark - Custom Images

- (UIImage *)playImage {
    if (!_playImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(20., 20.), NO, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        
        // |>
        [path moveToPoint:CGPointMake(0., 0.)];
        [path addLineToPoint:CGPointMake(20., 10.)];
        [path addLineToPoint:CGPointMake(0., 20.)];
        [path closePath];
        
        [[UIColor whiteColor] setFill];
        CGContextSetShadowWithColor(context, CGSizeMake(1., 0.), 5., [UIColor colorWithWhite:1. alpha:.5].CGColor);
        [path fill];
        
        _playImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _playImage;
}

- (UIImage *)pauseImage {
    if (!_pauseImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(20., 20.), NO, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // ||
        UIBezierPath *path1 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0., 0., 7., 20.) cornerRadius:1.];
        UIBezierPath *path2 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(20.-7., 0., 7., 20.) cornerRadius:1.];
        
        [[UIColor whiteColor] setFill];
        CGContextSetShadowWithColor(context, CGSizeMake(1., 0.), 5., [UIColor colorWithWhite:1. alpha:.5].CGColor);
        [path1 fill];
        [path2 fill];
        
        _pauseImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _pauseImage;
}

@end
