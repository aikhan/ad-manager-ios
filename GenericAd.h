//
//  GenericAd.h
//  Alien Tower
//
//  Created by Asad Khan on 05/02/2013.
//
//

#import <Foundation/Foundation.h>
#import "SNManager.h"
#import "MobclixAds.h"
#import "cocos2d.h"
#import "MobclixFullScreenAdViewController.h"
#import <RevMobAds/RevMobAds.h>
#import "Chartboost.h"
@class MobclixAdView;
@class RevMobFullscreen;
@class RevMobBanner;
@class GenericAd;

//@class MobclixFullScreenAdViewController;

@protocol GenericAdDelegate
@optional
- (void)revMobFullScreenDidFailToLoad:(GenericAd *)ad;
- (void)chartBoostFullScreenDidFailToLoad:(GenericAd *)ad;
- (void)mobClixFullScreenDidFailToLoad:(GenericAd *)ad;
- (void)revMobBannerDidFailToLoad:(GenericAd *)ad;
- (void)mobClixBannerDidFailToLoadBannerAd:(GenericAd *)ad;

- (void)revMobBannerDidLoadAd:(GenericAd *)ad;
- (void)mobClixBannerDidLoadAd:(GenericAd *)ad;
- (void)revMobFullScreenDidLoadAd:(GenericAd *)ad;
- (void)chartBoostFullScreenDidLoadAd:(GenericAd *)ad;
- (void)mobClixFullScreenDidLoadAd:(GenericAd *)ad;
@end


@interface GenericAd : NSObject <MobclixFullScreenAdDelegate, RevMobAdsDelegate, ChartboostDelegate, MobclixAdViewDelegate>

{
    MobclixFullScreenAdViewController* fullScreenAdViewController;
}
enum adNetworkType{
    kMobiClix,
    kChartBoost,
    kRevMob,
    kUndefined
};

enum adType{
    kBannerAd = 1000,
    kFullScreenAd,
    kButtonAd,
    kLinkAd,
    kPopUpAd,
    kLocalNotificationAd,
    kMoreAppsAd,
    kUndefinedAdType
};

@property(nonatomic, assign)NSUInteger adNetworkType;
@property(nonatomic, assign)NSUInteger adType;
@property(nonatomic, assign)BOOL isTestAd;
@property(nonatomic, assign)NSUInteger adPriority;
@property(nonatomic, assign)BOOL enableCaching;

@property(nonatomic, strong) RevMobFullscreen *revMobFullScreenAd;
//@property(nonatomic, strong) RevMobBanner *revMobBannerAd;
@property(nonatomic, strong)RevMobAdLink *adLink;
@property(nonatomic, strong) RevMobBannerView *revMobBannerAdView;
@property (nonatomic, retain) id <GenericAdDelegate> delegate;


@property (nonatomic, strong)Chartboost *chartBoost;


- (id) initWithAdNetworkType:(NSUInteger)adNetworkType andAdType:(NSUInteger)adType;
- (id) initWithAdType:(NSUInteger)adType;

-(void)showBannerAd;
-(void)showBannerAdAtTop;
-(void)showFullScreenAd;
-(void)showLinkButtonAd;
-(void)hideBannerAd;


/*
 *MobClix Specific Methods
 */

@property (retain, nonatomic) MobclixAdView *adView;
@property (assign, nonatomic) BOOL adStarted;

-(void) newAd:(CGPoint)loc;
-(void) showAd;
-(void) hideAd;
-(void) cancelAd;
//-(void) startMobclix;
-(NSString*) platform;

@end
