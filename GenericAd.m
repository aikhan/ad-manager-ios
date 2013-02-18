//
//  GenericAd.m
//  Alien Tower
//
//  Created by Asad Khan on 05/02/2013.
//
//

#import "GenericAd.h"
#import <RevMobAds/RevMobAds.h>
#import "Chartboost.h"
#import "Mobclix.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "SNAdsManager.h"
#import <RevMobAds/RevMobBanner.h>
#import "MobclixFullScreenAdViewController.h"

@implementation GenericAd

/**
Chartboost AdNetwork calls the didFailToLoadInterstitial: delegate method even when it tries and fails to load the cache which results in 2 callbacks. The Problem with our admanager than is it loads two lower priority ads. To mitigate this we will be using nstimer to distinguish between 2 consecutive calls. If the time difference between the calls is less than a specified limit we will ignore the second call.
 For this we will be declaring a static float variable to store first intial failure time and than we will compare it with every second call we wll recieve.

 Another option is to wait a predefined number of seconds before calling another ad network. This option is NOT currently implemented in this code.
*/

static double firstCallBackTime;
static int callBackCount;

@synthesize adNetworkType = _adNetworkType;
@synthesize adType = _adType;
@synthesize isTestAd = _isTestAd;
@synthesize adPriority = _adPriority;
@synthesize adView;
@synthesize adStarted;
@synthesize revMobFullScreenAd = _revMobFullScreenAd;
@synthesize delegate = _delegate;
//@synthesize revMobBannerAd = _revMobBannerAd;
@synthesize revMobBannerAdView = _revMobBannerAdView;
@synthesize adLink = _adLink;

//@synthesize mobClixFullScreenViewController = _mobClixFullScreenViewController;

- (id) initWithAdNetworkType:(NSUInteger)adNetworkType andAdType:(NSUInteger)adType{
	self = [super init];
	if(self !=nil){
        _adType = adType;
        _adNetworkType = adNetworkType;
        switch (adNetworkType) {
            case kMobiClix:
                if (_adType == kBannerAd){
                    adView.delegate = self;
                    _adPriority = kMobClixBannerAdPriority;
                }
                else if (adType == kFullScreenAd){
                    _adPriority = kMobClixFullScreenAdPriority;
                    fullScreenAdViewController = [[MobclixFullScreenAdViewController alloc] init];
                    fullScreenAdViewController.delegate = self;
                    [self prefetchMobClixFullScreenAd];
                }
                break;
            case kChartBoost:
                if (adType == kFullScreenAd){
                    _adPriority = kChartBoostFullScreeAdPriority;
                    self.chartBoost = [SNAdsManager sharedManager].chartBoost;
                    self.chartBoost.delegate = self;
                }
                else if (adType == kMoreAppsAd)
                    _adPriority = kChartBoostMoreAppsAd;
                break;
            case kRevMob:
                if(adType == kBannerAd){
                    _adPriority = kRevMobBannerAdPriority;
                    _revMobBannerAdView.delegate = self;
                }
                else if (adType == kFullScreenAd){
                    _adPriority = kRevMobFullScreenAdPriority;
                    _revMobFullScreenAd = [[RevMobAds session] fullscreen];
                    [_revMobFullScreenAd retain];
                    [_revMobFullScreenAd loadWithSuccessHandler:nil andLoadFailHandler:^(RevMobFullscreen *fs, NSError *error){
                            [self.delegate revMobFullScreenDidFailToLoad:self];
                    }];
                    
                }
                else if (adType == kButtonAd)
                    _adPriority = kRevMobButtonAdPriority;
                else if (adType == kLinkAd){
                    _adPriority = kRevMobLinkAdPriority;
                    self.adLink = [[RevMobAds session] adLinkWithPlacementId:nil]; // you must retain this object
                    [self.adLink retain];
                    self.adLink.delegate = self;
                    [self.adLink loadAd];
                }
                else if (adType == kPopUpAd)
                    _adPriority = kRevMobPopAdPriority;
                else if (adType == kLocalNotificationAd)
                    _adPriority = kRevMobLocalNotificationAdPriority;
                else
                    [NSException raise:@"Invalid Ad Type" format:@"Ad Type is invalid"];
                break;
            default:
               // NSAssert(!adNetworkType == kUndefined, @"Value for Ad Network cannot be Undefined");
                [NSException raise:@"Undefined Ad Network" format:@"Ad Network is unknown cannot continue"];
                break;
        }
	}
	return self;
}

- (id) initWithAdType:(NSUInteger)adType{
    self = [super init];
	if(self !=nil){
        _adType = adType;   
    }
    return self;
}

-(void)showBannerAdAtTop{
    switch(self.adNetworkType){
        case kRevMob:{
            @try {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        self.revMobBannerAdView.frame = CGRectMake(0, 0, screenWidth, 114);
                    } else {
                        self.revMobBannerAdView.frame = CGRectMake(0, 0, screenWidth, 50);
                    }
                        [[SNAdsManager getRootViewController].view addSubview:self.revMobBannerAdView];
                });
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
            @finally {
                //
            }
        }
            break;
        case kMobiClix:
            [self showAd];
            break;
        default:
            [NSException raise:@"Undefined Ad Network" format:@"Ad Network is unknown or does not have a banner Ad."];
            break;
    }
}

-(void)showBannerAd{
    switch(self.adNetworkType){
        case kRevMob:{
            @try {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.revMobBannerAdView = [[RevMobAds session] bannerView];
                    [self.revMobBannerAdView retain];
                    self.revMobBannerAdView.delegate = self;
                    [self.revMobBannerAdView loadAd];
                    NSUInteger screenHeight = [[UIScreen mainScreen] bounds].size.height;
                    NSUInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        self.revMobBannerAdView.frame = CGRectMake(0, screenHeight - 114, screenWidth, 114);
                    } else {
                        self.revMobBannerAdView.frame = CGRectMake(0, screenHeight - 50, screenWidth, 50);
                    }
                    self.revMobBannerAdView.hidden = NO;
                    [[SNAdsManager getRootViewController].view addSubview:self.revMobBannerAdView];
               });
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
            @finally {
                //
            }
        }
            break;
    case kMobiClix:
            [self showAd];
        break;
    default:
            [NSException raise:@"Undefined Ad Network" format:@"Ad Network is unknown or does not have a banner Ad."];
        break;
    }
}
-(void)showFullScreenAd{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    switch(self.adNetworkType){
        case kRevMob:
        {
            @try {
                if ([self.revMobFullScreenAd respondsToSelector:@selector(showAd)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.revMobFullScreenAd.delegate = self;
                        [self.revMobFullScreenAd showAd];
                    });
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
        }
            break;
        case kMobiClix:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showMobClixFullScreenAd];
            }); 
        }
            break;
        case kChartBoost:{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.chartBoost.delegate = self;
                [self.chartBoost showInterstitial];
            });
        }
            break;
        default:
            [NSException raise:@"Undefined Ad Network" format:@"Ad Network is unknown or does not have a banner Ad."];
            break;
    }
}
-(void)showLinkButtonAd{
    [self.adLink openLink];
}

-(void)hideBannerAd{
    //[self.revMobBannerAd hideAd];
    self.revMobBannerAdView.hidden = YES;
    [self.revMobBannerAdView removeFromSuperview];
}



#pragma mark -
#pragma mark MobClix Methods
-(NSString *) platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

-(void) newAd:(CGPoint)loc {
    
    if (adView) {
        // We only want one ad at a time
        [self cancelAd];
    }
    CGSize winSize = [UIScreen mainScreen].bounds.size;//
    bool is3GDevice = [[self platform] isEqualToString:@"iPhone1,2"];
    
    if (is3GDevice) {
        adView = [[[MobclixAdViewiPhone_320x50 alloc] initWithFrame:CGRectMake(-1 * (winSize.height/2 - 25 - loc.y), 160 - 25 + loc.x, 320.0f, 50.0f)] autorelease];
        [adView setTransform:CGAffineTransformMakeRotation(M_PI / 2.0)];
    }
    else if(winSize.width > 728) {
        adView = [[[MobclixAdViewiPad_728x90 alloc] initWithFrame:CGRectMake(loc.x+10,winSize.height - 100.0f, 728.0f, 90.0f)] autorelease];
    }
    
    else {
        adView = [[[MobclixAdViewiPhone_320x50 alloc] initWithFrame:CGRectMake(loc.x, winSize.height - loc.y - 50.0f, 320.0f, 50.0f)] autorelease];
    }
    
    [[SNAdsManager getRootViewController].view addSubview:adView];
    self.adView.delegate = self;
    [self.adView resumeAdAutoRefresh];
}
-(void) showAd {
    if (!adView)
        [self newAd:CGPointMake(0,0)];
    [self.adView resumeAdAutoRefresh];
    [self.adView setHidden:NO];
    [self.adView getAd];
}

-(void) hideAd {
    
    if (self.adView.hidden) {
        return;
    }
    [self.adView pauseAdAutoRefresh];
    [self.adView setHidden:YES];
    [self.adView removeFromSuperview];
}

-(void) cancelAd {
    // Can only cancel it if it exists
    if (adView) {
        [adView cancelAd];
        //[adView setDelegate:nil];
        [adView removeFromSuperview];
        adView = nil;
    }
}

-(void) startMobclix {
    if (!adStarted)
        adStarted = YES;
      //  [Mobclix startWithApplicationId:MOBCLIX_ID];
}

-(void)prefetchMobClixFullScreenAd{
   // [fullScreenAdViewController requestAd];
    //TODO:Get this fixed
   // [fullScreenAdViewController requestAd];
}

-(void)showMobClixFullScreenAd{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    UIViewController *rootViewController = [SNAdsManager getRootViewController];
    NSAssert(rootViewController, @"Ad cannot be displayed without view controller");
    //[fullScreenAdViewController displayRequestedAdFromViewController:rootViewController];
    [fullScreenAdViewController requestAndDisplayAdFromViewController:rootViewController];

}


- (void)revmobAdDidFailWithError:(NSError *)error{
    NSLog(@" Hey hey hey %s", __PRETTY_FUNCTION__);
    if (self.adType == kBannerAd) {
        [self.delegate revMobBannerDidFailToLoad:self];
        [self.revMobBannerAdView removeFromSuperview];
       // [[SNAdsManager sharedManager] revMobBannerDidFailToLoad:self];
    }else if (self.adType == kFullScreenAd){
        [self.delegate revMobFullScreenDidFailToLoad:self];
    }
}
- (void)revmobAdDisplayed{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.adType == kBannerAd) {
        [self.delegate revMobBannerDidLoadAd:self];
    }else if (self.adType == kFullScreenAd){
        [self.delegate revMobFullScreenDidLoadAd:self];
    }
}
- (void)revmobAdDidReceive{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.adType == kBannerAd) {
        [self.delegate revMobBannerDidLoadAd:self];
    }else if (self.adType == kFullScreenAd){
        //[self.delegate revMobFullScreenDidLoadAd:self];
    }
}
- (void)didFailToLoadInterstitial:(NSString *)location{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // NSLog(@"%@",[NSThread callStackSymbols]);
    /**
     On every callback increment the callback count by one
     on second callback check if the difference between first and second call is more than 1.5 sec
     If its more than 1.5 than most probably its a genuine failure callback
     else if its less than 3.5 just ignore it
     To make things quicker and not having to calculate nsdate instances everytime we're placing them in if else statements with respect to the callback counters.
     */
    callBackCount++;
    if(callBackCount == 1){
       firstCallBackTime = [[NSDate date] timeIntervalSince1970];
        [self.delegate chartBoostFullScreenDidFailToLoad:self];
    }
    else if (callBackCount == 2){
        NSDate *now = [NSDate date];
        double end = [now timeIntervalSince1970];
        double difference = end - firstCallBackTime;
        NSLog(@"Difference between calls is %f", difference);
        if (difference > 3.5) {
            [self.delegate chartBoostFullScreenDidFailToLoad:self];
        }
    }else{
        [self.delegate chartBoostFullScreenDidFailToLoad:self];
    }
        
    
}
- (BOOL)shouldDisplayLoadingViewForMoreApps{
    return YES;
}

- (void)fullScreenAdViewControllerDidFinishLoad:(MobclixFullScreenAdViewController*)fullScreenAdViewController{
    [self.delegate mobClixFullScreenDidLoadAd:self];
}

- (void)fullScreenAdViewController:(MobclixFullScreenAdViewController*)fullScreenAdViewController didFailToLoadWithError:(NSError*)error{
    //[self loadFullscreenAdWithLowerPriority];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"Error = %@", [error description]);
    [self.delegate mobClixFullScreenDidFailToLoad:self];
}
- (void)adViewDidFinishLoad:(MobclixAdView*)adView{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.delegate mobClixBannerDidLoadAd:self];
}
- (void)adView:(MobclixAdView*)adView didFailLoadWithError:(NSError*)error{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.delegate mobClixBannerDidFailToLoadBannerAd:self];
}

@end
