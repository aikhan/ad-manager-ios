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

@synthesize adNetworkType = _adNetworkType;
@synthesize adType = _adType;
@synthesize isTestAd = _isTestAd;
@synthesize adPriority = _adPriority;
@synthesize adView;
@synthesize adStarted;
@synthesize revMobFullScreenAd = _revMobFullScreenAd;
@synthesize delegate = _delegate;
@synthesize revMobBannerAd = _revMobBannerAd;
//@synthesize mobClixFullScreenViewController = _mobClixFullScreenViewController;

- (id) initWithAdNetworkType:(NSUInteger)adNetworkType andAdType:(NSUInteger)adType{
	self = [super init];
	if(self !=nil){
        _adType = adType;
        _adNetworkType = adNetworkType;
        switch (adNetworkType) {
            case kMobiClix:
                if (_adType == kBannerAd)
                    _adPriority = kMobClixBannerAdPriority;
                else if (adType == kFullScreenAd){
                    _adPriority = kMobClixFullScreenAdPriority;
                    fullScreenAdViewController = [[MobclixFullScreenAdViewController alloc] init];
                    fullScreenAdViewController.delegate = self;
                    [self prefetchMobClixFullScreenAd];
                }
                break;
            case kChartBoost:
                if (adType == kFullScreenAd) 
                    _adPriority = kChartBoostFullScreeAdPriority;
                else if (adType == kMoreAppsAd)
                    _adPriority = kChartBoostMoreAppsAd;
                break;
            case kRevMob:
                if(adType == kBannerAd){
                    _adPriority = kRevMobBannerAdPriority;
                    _revMobBannerAd = [[RevMobAds session] banner];
                    [_revMobBannerAd loadAd];
                }
                else if (adType == kFullScreenAd){
                    _adPriority = kRevMobFullScreenAdPriority;
                    _revMobFullScreenAd = [[RevMobAds session] fullscreen];
                    [_revMobFullScreenAd loadWithSuccessHandler:nil andLoadFailHandler:^(RevMobFullscreen *fs, NSError *error){
                            [self.delegate revMobFullScreenDidFailToLoad:self];
                    }];
                }
                else if (adType == kButtonAd)
                    _adPriority = kRevMobButtonAdPriority;
                else if (adType == kLinkAd)
                    _adPriority = kRevMobLinkAdPriority;
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

-(void)showBannerAd{
    switch(self.adNetworkType){
        case kRevMob:{
            @try {
                //[self.revMobBannerAd showAd];
                [[RevMobAds session] showBanner];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
            @finally {
                [[RevMobAds session] showBanner];
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
            /*if ([self.revMobFullScreenAd respondsToSelector:@selector(showAd)]) {
                
            }else{
             */ //This seems to fail sometimes I dont know the reason why even the respondsToSelector crashes ...?
                // RevMob SDK have far too many problems
                
           // }
            @try {
                //[self.revMobFullScreenAd showAd];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[RevMobAds session] showFullscreen];
                });
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
            @finally {
                [[RevMobAds session] showFullscreen];
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
                [[SNAdsManager sharedManager].chartBoost showInterstitial];
            });
        }
            break;
        default:
            [NSException raise:@"Undefined Ad Network" format:@"Ad Network is unknown or does not have a banner Ad."];
            break;
    }
}
-(void)showLinkButtonAd{
    
}

-(void)hideBannerAd{
    
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
    CGSize winSize = [[CCDirector sharedDirector] winSize];//[UIScreen mainScreen].bounds.size;//
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
    //    [[[self getRootViewController] view] addSubview:adView];
    [[[CCDirector sharedDirector] openGLView] addSubview:adView];
    
    [self.adView resumeAdAutoRefresh];
}
-(void) showAd {
    if (!adView)
        [self newAd:ccp(0,0)];
    [self.adView resumeAdAutoRefresh];
    [self.adView setHidden:NO];
}

-(void) hideAd {
    [self.adView pauseAdAutoRefresh];
    [self.adView setHidden:YES];
}

-(void) cancelAd {
    // Can only cancel it if it exists
    if (adView) {
        [adView cancelAd];
        [adView setDelegate:nil];
        [adView removeFromSuperview];
        adView = nil;
    }
}

-(void) startMobclix {
    if (!adStarted)
        adStarted = YES;
        [Mobclix startWithApplicationId:MOBCLIX_ID];
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
- (void)fullScreenAdViewController:(MobclixFullScreenAdViewController*)fullScreenAdViewController didFailToLoadWithError:(NSError*)error{
    //[self loadFullscreenAdWithLowerPriority];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"Error = %@", [error description]);
    [self.delegate mobClixFullScreenDidFailToLoad:self];
}
@end
