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
#endif


#define kAdTimeOutThresholdValue 3.0

#define kRevMobId @"508b256d3628350d00000025"

#define ChartBoostAppID @"4f9f7ac4f876590f1000000b" // Neon Tower Paid
#define ChartBoostAppSignature @"6afe30b73b3ae4bc74892e6685f0a68c5c2ba1c8" //Neon tower Paid

#define MOBCLIX_ID @"B7C698A4-FFF5-4B2F-822F-25170F8858C3"//@"2C63EF1A-CA74-4467-8D30-1032D073A367"//2C63EF1A-CA74-4467-8D30-1032D073A367" // neon Tower Free
//@"665A8F99-D0E1-49ED-9CB9-992EBDCA5619"//

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
#define kRevMobFullScreenAdPriority kPriorityNORMAL //Full Screen Pop-ups
#define kRevMobButtonAdPriority kPriorityHIGHEST //Button ads this is not currently used in games, its just a wrapper on Link Ads
#define kRevMobLinkAdPriority kPriorityHIGHEST  //This is the Ad that is displayed on buttons on game over screens
#define kRevMobPopAdPriority kPriorityHIGHEST  //UIAlert type pop-up Ads in games
#define kRevMobLocalNotificationAdPriority kPriorityHIGHEST // UILocalNotification Ads //Currently we're not using it

#define kChartBoostFullScreeAdPriority kPriorityHIGHEST
#define kChartBoostMoreAppsAd kPriorityHIGHEST

#define kMobClixBannerAdPriority kPriorityNORMAL
#define kMobClixFullScreenAdPriority kPriorityLOWEST

#define kNumberOfAdNetworks 3

@interface SNManager : NSObject



@end
