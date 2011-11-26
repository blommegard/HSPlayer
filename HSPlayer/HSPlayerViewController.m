//
//  HSPlayerViewController.m
//  HSPlayer
//
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.
//

#import "HSPlayerViewController.h"
#import "HSPlayerView.h"

@interface HSPlayerViewController ()
@property (nonatomic, strong) HSPlayerView *playerView;
@end

@implementation HSPlayerViewController

@synthesize playerView = _playerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self setWantsFullScreenLayout:YES];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setPlayerView:[[HSPlayerView alloc] initWithFrame:self.view.frame]];
    [self.playerView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
     
    [self.view addSubview:self.playerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.playerView setFrame:self.view.bounds];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.playerView setURL:[NSURL URLWithString:@"http://www0.c90910.dna.qbrick.com/90910/od/20110206/0602_sammandrag1645-hts-a-v1/0602_sammandrag1645-hts-a-v1_vod.m3u8"]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
