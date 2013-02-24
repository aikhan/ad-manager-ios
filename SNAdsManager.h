//
//  SNAdsManager.h
//  Alien Tower
//
//  Created by Asad Khan on 05/02/2013.
//
//


/*
 * All of the SDKs for the Ad Networks are very different architecturally. 
 * For RevMob and MobClix Generic Ad class provides a nice wrapper and almost everything can be manipulated through it.
 * For Chartboost Generic Ad class provides a very thin wrapper calls are basically just rerouted but again doing this highly decouples our design
 * & improves overall quality and structure.
 */

#import <Foundation/Foundation.h>
#import "SNManager.h"
#import "MobclixAds.h"
#import "GenericAd.h"

@protocol SNAdsManagerDelegate <NSObject>
@optional
/**
 Delegate Method to notify that fullscreen Ad has failed to load.
 All failovers have also failed.
 */
- (void)fullScreenAdDidFailToLoad;
/**
 Delegate Method to notify that fullscreen Ad has failed to load.
 All failovers have also failed.
 */
- (void)bannerAdDidFailToLoad;
/**
 Delegate Method to notify that Link Ad has failed to load.
 All failovers have also failed.
 */
- (void)linkAdDidFailToLoad;
/**
 Delegate Method to notify that fullscreen Ad has loaded

 */
- (void)fullScreenAdDidLoad;
/**
 Delegate Method to notify that banner Ad has loaded.

 */
- (void)bannerAdDidLoad;
/**
 Delegate Method to notify that RevMob fullscreen Ad has failed to load.
 An attempt to load another ad from a different network will also be made if there is a lower priority Ad from another network.
 If for some reason other network also fails the - (void)fullScreenAdDidFailToLoad; will be called.
 */
- (void)revMobFullScreenDidFailToLoad;
/**
 Delegate Method to notify that fullscreen Ad has loaded.
 */
- (void)revMobFullScreenAdDidLoad;
/**
 Delegate Method to notify that ChartBoost fullscreen Ad has failed to load.
 An attempt to load another ad from a different network will also be made if there is a lower priority Ad from another network.
 If for some reason other network also fails the - (void)fullScreenAdDidFailToLoad; will be called.
 */
- (void)chartBoostFullScreenDidFailToLoad;
/**
 Delegate Method to notify that MobClix fullscreen Ad has failed to load.
 An attempt to load another ad from a different network will also be made if there is a lower priority Ad from another network.
 If for some reason other network also fails attempt to load ads will fail gracefully.
 */
- (void)mobClixFullScreenDidFailToLoad;
/**
 Delegate Method to notify that RevMob Banner Ad has failed to load.
 An attempt to load another ad from a different network will also be made if there is a lower priority Ad from another network.
 If for some reason other network also fails the request to load banner ad will fail gracefully.
 */
- (void)revMobBannerDidFailToLoad;
/**
 Delegate Method to notify that RevMob Banner Ad has loaded.
 */
- (void)revMobBannerDidLoad;

/**
 Delegate Method to notify that MobClix Banner Ad has loaded.
 */
- (void)mobClixBannerDidLoad;
/**
 Delegate Method to notify that PlayHaven FullScreen Ad has Failed to loaded.
 */
- (void)playHavenFullScreenDidFailToLoad;

/**
 Delegate Method to notify that PlayHaven FullScreen Ad has loaded.
 */
- (void)playHavenFullScreenDidLoad;
@end



@interface SNAdsManager : SNManager <GenericAdDelegate>


@property (nonatomic, strong)GenericAd *genericAd;
@property (nonatomic, strong)NSMutableArray *currentAdsBucketArray;
@property (nonatomic, assign) ConnectionStatus myConnectionStatus;

@property (nonatomic, strong)Chartboost *chartBoost;
@property (nonatomic, strong)NSTimer *adTimer; //Ad timeout threshold Timer
@property (nonatomic, unsafe_unretained) id <SNAdsManagerDelegate> delegate;


+ (SNAdsManager *)sharedManager;
+ (UIViewController *)getRootViewController;

/*
 * Methods for Generic Ad retrieval based on the priority levels defined
 */
- (void) giveMeBannerAd;
- (void) giveMeBannerAdAtTop;
- (void) giveMeFullScreenAd;
- (void) giveMeLinkAd;
- (void) giveMeMoreAppsAd;

- (void) hideBannerAd;

/*
 * Call ChartBoost Methods Directly, methods are just empty stubs calling ChartBoost counterparts
 */
- (void) giveMeFullScreenChartBoostAd;
- (void) giveMeMoreAppsChartBoostAd;

/*
 * Call RevMob Methods Directly, methods are just empty stubs calling RevMob counterparts
 */
- (void) giveMeFullScreenRevMobAd;
- (void) giveMeBannerRevMobAd;
- (void) giveLinkRevMobAd;


/*
 * Call Mobclix Methods Directly, methods are just empty stubs calling mobclix counterparts
 */
- (void) giveMeBannerMobclixAd;
- (void) giveMeFullScreenMobClixAd;


/**
 Further Methods to ease usage
 */
- (void)giveMeThirdGameOverAd;
- (void)giveMeGameOverAd;
- (void)giveMeBootUpAd;
- (void)giveMeWillEnterForegroundAd;
- (void)giveMePaidFullScreenAd;
@end
