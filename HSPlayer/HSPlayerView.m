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
@property (nonatomic, strong) UIView *topControlView;
@property (nonatomic, strong) UIButton *closeControlButton;
@property (nonatomic, strong) UISlider *scrubberControlSlider;
@property (nonatomic, strong) UILabel *currentPlayerTimeLabel;
@property (nonatomic, strong) UILabel *remainingPlayerTimeLabel;

@property (nonatomic, strong) UIView *bottomControlView;
@property (nonatomic, strong) UIButton *playPauseControlButton;

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

@synthesize fullScreen = _fullScreen;

@synthesize controls = _controls;
@synthesize topControlView = _topControlView;
@synthesize closeControlButton = _closeControlButton;
@synthesize scrubberControlSlider = _scrubberControlSlider;
@synthesize currentPlayerTimeLabel = _currentPlayerTimeLabel;
@synthesize remainingPlayerTimeLabel = _remainingPlayerTimeLabel;

@synthesize bottomControlView = _bottomControlView;
@synthesize playPauseControlButton = _playPauseControlButton;

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
        [self setFullScreen:YES];
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
            [self setPlayerTimeObserver:nil];
        }
        else {
            // New title
            [self syncPlayPauseButton];
            
            
            __unsafe_unretained HSPlayerView *weakSelf = self;
            [self setPlayerTimeObserver:[self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(.5, NSEC_PER_SEC)
                                                                                  queue:dispatch_get_main_queue()
                                                                             usingBlock:^(CMTime time) {
                                                                                 
                                                                                 HSPlayerView *strongSelf = weakSelf;
                                                                                 
                                                                                 if (CMTIME_IS_VALID(strongSelf.player.currentTime) && CMTIME_IS_VALID(strongSelf.duration)) {
                                                                                 
                                                                                 NSInteger currentSeconds = ceilf(CMTimeGetSeconds(strongSelf.player.currentTime)); 
                                                                                 NSInteger seconds = currentSeconds % 60;
                                                                                 NSInteger minutes = currentSeconds / 60;
                                                                                 NSInteger hours = minutes / 60;
                                                                                 
                                                                                 NSInteger duration = ceilf(CMTimeGetSeconds(strongSelf.duration));
                                                                                 NSInteger currentDurationSeconds = duration-currentSeconds;
                                                                                 NSInteger durationSeconds = currentDurationSeconds % 60;
                                                                                 NSInteger durationMinutes = currentDurationSeconds / 60;
                                                                                 NSInteger durationHours = durationMinutes / 60;
                                                                                 
                                                                                 [strongSelf.currentPlayerTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds]];
                                                                                 [strongSelf.remainingPlayerTimeLabel setText:[NSString stringWithFormat:@"- %02d:%02d:%02d", durationHours, durationMinutes, durationSeconds]];
                                                                                 }
                                                                             }]];
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
        // Show/hide airplay-image
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

- (void)setFullScreen:(BOOL)fullScreen {
    [self willChangeValueForKey:@"fullScreen"];
    _fullScreen = fullScreen;
    [self didChangeValueForKey:@"fullScreen"];
    
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen withAnimation:UIStatusBarAnimationFade];
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

#pragma mark - Controls

- (NSArray *)controls {
    if (!_controls) {
        _controls = [NSArray arrayWithObjects:
                     self.topControlView,
                     self.bottomControlView,
                     nil];
    }
    
    return _controls;
}

- (UIView *)topControlView {
    if (!_topControlView) {
        _topControlView = [[UIView alloc] initWithFrame:CGRectMake(0., 20., self.bounds.size.width, 40.)];
        [_topControlView setBackgroundColor:[UIColor colorWithWhite:0. alpha:.5]];
        [_topControlView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
        
        [self.currentPlayerTimeLabel setFrame:CGRectMake(10., 20., 100., 20.)];
        [_topControlView addSubview:self.currentPlayerTimeLabel];
        
        [self.remainingPlayerTimeLabel setFrame:CGRectMake(_topControlView.bounds.size.width-100.-10., 20., 100., 20.)];
        [_topControlView addSubview:self.remainingPlayerTimeLabel];
    }
    
    return _topControlView;
}

- (UILabel *)currentPlayerTimeLabel {
    if (!_currentPlayerTimeLabel) {
        _currentPlayerTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_currentPlayerTimeLabel setBackgroundColor:[UIColor clearColor]];
        [_currentPlayerTimeLabel setTextColor:[UIColor whiteColor]];
        [_currentPlayerTimeLabel setFont:[UIFont systemFontOfSize:12.]];
    }
    
    return _currentPlayerTimeLabel;
}

- (UILabel *)remainingPlayerTimeLabel {
    if (!_remainingPlayerTimeLabel) {
        _remainingPlayerTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_remainingPlayerTimeLabel setBackgroundColor:[UIColor clearColor]];
        [_remainingPlayerTimeLabel setTextColor:[UIColor whiteColor]];
        [_remainingPlayerTimeLabel setFont:[UIFont systemFontOfSize:12.]];
        [_remainingPlayerTimeLabel setTextAlignment:UITextAlignmentRight];
        [_remainingPlayerTimeLabel setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin)];
    }
    
    return _remainingPlayerTimeLabel;
}

- (UIButton *)closeControlButton {
    return _closeControlButton;
}

- (UISlider *)scrubberControlSlider {
    if (!_scrubberControlSlider) {
        _scrubberControlSlider = [[UISlider alloc] initWithFrame:CGRectZero];
        [_scrubberControlSlider setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
        
        // Add sync for changed value..
    }
    
    return _scrubberControlSlider;
}

- (UIView *)bottomControlView {
    if (!_bottomControlView) {
        _bottomControlView = [[UIView alloc] initWithFrame:CGRectMake(0., self.bounds.size.height-40., self.bounds.size.width, 40.)];
        [_bottomControlView setBackgroundColor:[UIColor colorWithWhite:0. alpha:.5]];
        [_bottomControlView setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth)];

        MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(40., 11., _bottomControlView.bounds.size.width-50., 18.)];
        [volumeView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
        [_bottomControlView addSubview:volumeView];

        [self.playPauseControlButton setFrame:CGRectMake(10., 10., 20., 20.)];
        [_bottomControlView addSubview:self.playPauseControlButton];
    }
    
    return _bottomControlView;
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

#pragma mark -

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

#pragma mark Public

- (void)play:(id)sender {
	if (self.seekToZeroBeforePlay)  {
		[self setSeekToZeroBeforePlay:NO];
		[self.player seekToTime:kCMTimeZero];
	}
    
    [self.player play];
}

- (void)pause:(id)sender {
    [self.player pause];
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
    
    if (self.fullScreen)
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
        CGContextSetShadowWithColor(context, CGSizeMake(1., 0.), 2., [UIColor colorWithWhite:1. alpha:.5].CGColor);
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
        CGContextSetShadowWithColor(context, CGSizeMake(1., 0.), 2., [UIColor colorWithWhite:1. alpha:.5].CGColor);
        [path1 fill];
        [path2 fill];
        
        _pauseImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _pauseImage;
}

@end
