//
//  SNManager.h
//  Alien Tower
//
//  Created by Asad Khan on 05/02/2013.
//
//

#import <Foundation/Foundation.h>

#import <Availability.h>

/*
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif
*/

#ifdef DEBUG
#define DebugLog(f, ...) NSLog(f, ## __VA_ARGS__)
#else
#define DebugLog(f, ...)
//#define NS_BLOCK_ASSERTIONS
#endif



#define kPlayHavenAdTimeOutThresholdValue 4.0
#define kRevMobAdTimeOutThresholdValue 3.0

#ifdef FreeApp
#define kRevMobId @"516e6d24b6e71a73a20000b6"

#define ChartBoostAppID @"516e686917ba479e2b00000b"
#define ChartBoostAppSignature @"05b80fa6354259abc591bc2b7d05490370504b6e"

#define MOBCLIX_ID @"57EEB2FE-A593-4201-95E8-22134D0C4B3F"
#define kPlayHavenAppToken @"a411aa86739d4ad7840ed7839ffc8349"
#define kPlayHavenSecret @"ab203658d4894b02bf13e8d72863d427"
#define kPlayHavenPlacement @"main_menu"

#define kTapJoyAppID @""
#define kTapJoySecretKey @""
#define kRateURL @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=634212776"

#endif

#ifdef PaidApp
#define kRevMobId @"516e6d24b6e71a73a20000b6"

#define ChartBoostAppID @"516e686917ba479e2b00000b"
#define ChartBoostAppSignature @"05b80fa6354259abc591bc2b7d05490370504b6e"

#define MOBCLIX_ID @""
#define kPlayHavenAppToken @""
#define kPlayHavenSecret @""
#define kPlayHavenPlacement @"main_menu"

#define kTapJoyAppID @""
#define kTapJoySecretKey @""
#define kRateURL @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=634212863"
#endif

typedef NS_ENUM(NSUInteger, adPriorityLevel){
    kPriorityLOWEST = 10,
    kPriorityNORMAL,
    kPriorityHIGHEST
};

typedef NS_ENUM(NSUInteger, ConnectionStatus) {
   
    kNotAvailable,
    kWANAvailable,
    kWifiAvailable
    
};

/*
 These are the default values before changing them do consult Angela
 */
#define kRevMobBannerAdPriority kPriorityHIGHEST  //In Game banner Ads
#define kRevMobFullScreenAdPriority kPriorityLOWEST //Full Screen Pop-ups
#define kRevMobButtonAdPriority kPriorityHIGHEST //Button ads this is not currently used in games, its just a wrapper on Link Ads
#define kRevMobLinkAdPriority kPriorityHIGHEST  //This is the Ad that is displayed on buttons on game over screens
#define kRevMobPopAdPriority kPriorityHIGHEST  //UIAlert type pop-up Ads in games
#define kRevMobLocalNotificationAdPriority kPriorityHIGHEST // UILocalNotification Ads //Currently we're not using it

#define kChartBoostFullScreeAdPriority kPriorityHIGHEST
#define kChartBoostMoreAppsAd kPriorityHIGHEST

#define kMobClixBannerAdPriority kPriorityNORMAL
#define kMobClixFullScreenAdPriority kPriorityNORMAL


#define kPlayHavenFullScreenAdPriority kPriorityNORMAL



#define kNumberOfAdNetworks 5





@interface SNManager : NSObject



@end
