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

static int count = 0;

@interface GenericAd()

@property (nonatomic, retain) NSTimer *playHavenTimer;
@property (nonatomic, assign)BOOL hasPlayHavenAdLoaded;
@end


@implementation GenericAd

/**
Chartboost AdNetwork calls the didFailToLoadInterstitial: delegate method even when it tries and fails to load the cache which results in 2 callbacks. The Problem with our admanager than is it loads two lower priority ads. To mitigate this we will be using nstimer to distinguish between 2 consecutive calls. If the time difference between the calls is less than a specified limit we will ignore the second call.
 For this we will be declaring a static float variable to store first intial failure time and than we will compare it with every second call we wll recieve.

 Another option is to wait a predefined number of seconds before calling another ad network. This option is NOT currently implemented in this code.
*/

static double firstCallBackTime;
static int callBackCount;

/**
 Sometimes RevMob fails to notify that loading ad has been failed so as a back we're adding fail time for RevMob FullScreen and Banner both
 */


@synthesize adNetworkType = _adNetworkType;
@synthesize adType = _adType;
@synthesize isTestAd = _isTestAd;
@synthesize adPriority = _adPriority;
@synthesize adView;
@synthesize adStarted;
@synthesize revMobFullScreenAd = _revMobFullScreenAd;
@synthesize delegate = _delegate;

@synthesize revMobBannerAdView = _revMobBannerAdView;
@synthesize adLink = _adLink;
@synthesize revMobFullScreenAdTimer = _revMobFullScreenAdTimer;
@synthesize isRevMobFullScreenAlreadyShown = _isRevMobFullScreenAlreadyShown;
@synthesize playHavenTimer = _playHavenTimer;
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
            case kPlayHaven:
                if (adType == kFullScreenAd) {
                    _adPriority = kPlayHavenFullScreenAdPriority;
                    [[PHPublisherContentRequest requestForApp:kPlayHavenAppToken secret:kPlayHavenSecret placement:kPlayHavenPlacement delegate:self] preload];
                }
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
                    //_revMobFullScreenAd.delegate = self;
                    [_revMobFullScreenAd loadWithSuccessHandler:nil andLoadFailHandler:^(RevMobFullscreen *fs, NSError *error){
                          //  [self.delegate revMobFullScreenDidFailToLoad:self];
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
                    CGSize size = [GenericAd currentSize];
                    NSUInteger screenHeight = size.height;
                    NSUInteger screenWidth = size.width;
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        self.revMobBannerAdView.frame = CGRectMake(0, screenHeight-114, screenWidth, 114);
                    } else {
                        self.revMobBannerAdView.frame = CGRectMake(0, screenHeight-50, screenWidth, 50);
                    }
                    self.revMobBannerAdView.hidden = NO;
                    [[SNAdsManager getRootViewController].view addSubview:self.revMobBannerAdView];
                    [[SNAdsManager getRootViewController].view bringSubviewToFront:self.revMobBannerAdView];
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
                if (self.isRevMobFullScreenAlreadyShown) {
                    NSLog(@"DID NOT LOAD MOBCLIX");
                    return;
                }
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
        case kPlayHaven:{
            count++;
            NSLog(@"COunt for play HAVEN %d", count);
            [self showPlayHavenFullScreenAd];
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
+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}
+(CGSize) currentSize
{
    return [GenericAd sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}
-(void)hideBannerAd{
    
    self.revMobBannerAdView.hidden = YES;
    [self.revMobBannerAdView removeFromSuperview];
    self.revMobBannerAdView = nil;
   // self.revMobBannerAdView.frame = CGRectMake(-400, -400, -400, -400);
}

- (void)showPlayHavenFullScreenAd{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    DebugLog(@"YAAY PLAY HAVEN");
    PHPublisherContentRequest * request = [PHPublisherContentRequest requestForApp:kPlayHavenAppToken secret:kPlayHavenSecret placement:kPlayHavenPlacement delegate:self];
    [request setShowsOverlayImmediately:YES];
    [request setAnimated:YES];
    [request send];
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
    self.adView.refreshTime = 10;
    [self.adView resumeAdAutoRefresh];
}
-(void) showAd {
    if (!adView)
        [self newAd:CGPointMake(0,0)];
    [[SNAdsManager getRootViewController].view addSubview:self.adView];
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
    [self.adView retain];
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

//TODO: This is not a good way to do this from what I can tell, but until 
- (void)revmobAdDidFailWithError:(NSError *)error{
    NSLog(@" Hey hey hey %s", __PRETTY_FUNCTION__);
    if (self.adType == kBannerAd) {
        NSLog(@"REVMOB BANNER FAILED");
        
            [self.delegate revMobBannerDidFailToLoad:self];
            [self.revMobBannerAdView removeFromSuperview];
//            [self.revMobBannerAdTimer invalidate];
//            self.revMobBannerAdTimer = nil;
        
    }else if (self.adType == kFullScreenAd){
        NSLog(@"REVMOB FULLSCREEN FAILED");
            [self.delegate revMobFullScreenDidFailToLoad:self];
//            [self.revMobFullScreenAdTimer invalidate];
//            self.revMobFullScreenAdTimer = nil;
    }
}
- (void)revmobAdDisplayed{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.adType == kBannerAd) {
        [self.delegate revMobBannerDidLoadAd:self];

    }else if (self.adType == kFullScreenAd){

        [self.delegate revMobFullScreenDidLoadAd:self];
        self.isRevMobFullScreenAlreadyShown = YES;
    }
}
- (void)revmobUserClosedTheAd{
    if(self.adType == kFullScreenAd){
        self.isRevMobFullScreenAlreadyShown = NO;
    }
}
- (void)revmobAdDidReceive{
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.adType == kBannerAd) {
        [self.delegate revMobBannerDidLoadAd:self];
    }else if (self.adType == kFullScreenAd){
        [self.delegate revMobFullScreenDidLoadAd:self];
    }
}
- (void)didFailToLoadInterstitial:(NSString *)location{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // NSLog(@"%@",[NSThread callStackSymbols]);
    /**
     On every callback increment the callback count by one
     on second callback check if the difference between first and second call is more than 1.5 sec
     If its more than 4.5 than most probably its a genuine failure callback
     else if its less than 4.5 just ignore it
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
        if (difference > 4.5) {
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


#pragma mark -
#pragma mark Play Haven

-(void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    //[self.delegate playHavenFullScreenDidLoadAd:self];
    
}

-(void)request:(PHPublisherContentRequest *)request didFailWithError:(NSError *)error{
    if (self.hasPlayHavenAdLoaded) {
        return;
    }
    self.hasPlayHavenAdLoaded = YES;
    [self.delegate playHavenFullScreenDidFailToLoad:self];
}


-(void)requestDidGetContent:(PHPublisherContentRequest *)request{
    self.hasPlayHavenAdLoaded = YES;
}

-(void)requestWillGetContent:(PHPublisherContentRequest *)request{
    self.playHavenTimer = [NSTimer scheduledTimerWithTimeInterval:kPlayHavenAdTimeOutThresholdValue target:self selector:@selector(request:didFailWithError:) userInfo:nil repeats:NO];
    self.hasPlayHavenAdLoaded = NO;
}
@end
