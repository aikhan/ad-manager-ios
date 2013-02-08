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
@class MobclixAdView;
@class RevMobFullscreen;
@class RevMobBanner;
@class GenericAd;
//@class MobclixFullScreenAdViewController;

@protocol GenericAdDelegate
@optional
- (void)revMobFullScreenDidFailToLoad:(GenericAd *)ad;
- (void)mobClixFullScreenDidFailToLoad:(GenericAd *)ad;
@end


@interface GenericAd : NSObject <MobclixFullScreenAdDelegate>

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
@property(nonatomic, strong) RevMobBanner *revMobBannerAd;
@property (nonatomic, retain) id <GenericAdDelegate> delegate;



- (id) initWithAdNetworkType:(NSUInteger)adNetworkType andAdType:(NSUInteger)adType;
- (id) initWithAdType:(NSUInteger)adType;

-(void)showBannerAd;
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
