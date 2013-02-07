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
#import <RevMobAds/RevMobAds.h>
#import "MobclixAds.h"
#import "ChartBoost.h"
#import "GenericAd.h"
#import "MobclixFullScreenAdViewController.h"




@interface SNAdsManager : SNManager <RevMobAdsDelegate, ChartboostDelegate, GenericAdDelegate>


@property (nonatomic, strong)GenericAd *genericAd;
@property (nonatomic, strong)NSMutableArray *currentAdsBucketArray;
@property (nonatomic, assign) ConnectionStatus myConnectionStatus;

@property (nonatomic, strong)Chartboost *chartBoost;
@property (nonatomic, strong)NSTimer *adTimer; //Ad timeout threshold Timer



+ (SNAdsManager *)sharedManager;
+ (UIViewController *)getRootViewController;

/*
 * Methods for Generic Ad retrieval based on the priority levels defined
 */
- (void) giveMeBannerAd;
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
@end
