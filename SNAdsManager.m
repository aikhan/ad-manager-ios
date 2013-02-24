//
//  SNAdsManager.m
//  Alien Tower
//
//  Created by Asad Khan on 05/02/2013.
//
//

#import "SNAdsManager.h"
#import "GenericAd.h"
#import "Reachability.h"
#import "Mobclix.h"
#import "SNQueue.h"
#import "AppDelegate.h"
#import "TapjoyConnect.h"


static NSUInteger gameOverCount = 0;

@interface SNAdsManager()


@property (nonatomic, strong)NSArray *sortedBannerAdsArray;
@property (nonatomic, assign)NSUInteger currentBannerAdIndex;
@property (nonatomic, strong)NSArray *sortedFullScreenAdsArray;
@property (nonatomic, assign)NSUInteger currentSortedFullScreenAdIndex;

@property (nonatomic, assign)BOOL haveAdNetworksInitialized;
@property (nonatomic, strong)SNQueue *adRequestQueue;

- (void)loadAdWithLowerPriorityThanPreviousAd:(GenericAd*)ad;
- (void)loadBannerAdWithLowerPriorityhanPreviousAd:(GenericAd*)previousFailedAd;
- (void)loadFullscreenAdWithLowerPriorityThanPreviousAd:(GenericAd*)previousFailedAd;
- (void)loadLinkAdWithLowerPriorityThanPreviousAd:(GenericAd*)previousFailedAd;
- (void)failGracefully:(GenericAd*)previousAd;

- (ConnectionStatus)isReachableVia;
- (void) initializeAdNetworks;
- (void)startMobclix;
- (void)startRevMob;
- (void)startChartBoost;



@end


@implementation SNAdsManager

@synthesize myConnectionStatus = _myConnectionStatus;
@synthesize genericAd = _genericAd;
@synthesize currentAdsBucketArray = _currentAdsBucketArray;
@synthesize chartBoost = _chartBoost;
@synthesize adTimer = _adTimer;
@synthesize sortedBannerAdsArray = _sortedBannerAdsArray;
@synthesize sortedFullScreenAdsArray = _sortedFullScreenAdsArray;
@synthesize currentBannerAdIndex;
@synthesize currentSortedFullScreenAdIndex;
@synthesize haveAdNetworksInitialized = _haveAdNetworksInitialized;
@synthesize adRequestQueue = _adRequestQueue;

static int callBackCount = 0; //KVO count for NSOperation objects in Ad Networks initialization

#pragma mark -
#pragma mark Singleton Methods

static SNAdsManager *sharedManager = nil;

+ (SNAdsManager*)sharedManager{
    if (sharedManager != nil)
    {
        return sharedManager;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    static dispatch_once_t safer;
    dispatch_once(&safer, ^(void)
                  {
                      sharedManager = [[SNAdsManager alloc] init];
                      
                  });
#else
    @synchronized([SNAdsManager class])
    {
        if (sharedManager == nil)
        {
            sharedManager = [[SNAdsManager alloc] init];
            
        }
    }
#endif
    return sharedManager;
}



- (id)copyWithZone:(NSZone *)zone{
	return self;
}

- (id) init{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
	self = [super init];
	if(self !=nil){
        self.myConnectionStatus = [self isReachableVia];
        //_genericAd.isTestAd = [self isSimulator];
        
        _currentAdsBucketArray = [[NSMutableArray alloc] init];
        //if(self.myConnectionStatus != kNotReachable){
            [self initializeAdNetworks];
        //}else{
            NSLog(@"!!!Offline!!!");
        //}
	}
	return self;
	
}//end init

- (void)dealloc {
	NSLog(@"dealloc called");
    return;
    [super dealloc];
}

- (void)fetchAds{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    
    GenericAd *chartBoostFullScreenAd = [[GenericAd alloc] initWithAdNetworkType:kChartBoost andAdType:kFullScreenAd];
    chartBoostFullScreenAd.delegate = self;
    [self.currentAdsBucketArray addObject:chartBoostFullScreenAd];
    
    GenericAd *chartBoostMoreAppsAd = [[GenericAd alloc] initWithAdNetworkType:kChartBoost andAdType:kMoreAppsAd];
    chartBoostMoreAppsAd.delegate = self;
    [self.currentAdsBucketArray addObject:chartBoostMoreAppsAd];
    
    GenericAd *playHavenFullScreenAd = [[GenericAd alloc] initWithAdNetworkType:kPlayHaven andAdType:kFullScreenAd];
    playHavenFullScreenAd.delegate = self;
    [self.currentAdsBucketArray addObject:playHavenFullScreenAd];
    
    GenericAd *revMobBannerAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kBannerAd];
    revMobBannerAd.delegate = self;
    [self.currentAdsBucketArray addObject:revMobBannerAd];
    
    GenericAd *revMobFullScreenAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kFullScreenAd];
    revMobFullScreenAd.delegate = self;
    [self.currentAdsBucketArray addObject:revMobFullScreenAd];
    
    GenericAd *revMobLinkAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kLinkAd];
    revMobLinkAd.delegate = self;
    [self.currentAdsBucketArray addObject:revMobLinkAd];
    
    GenericAd *mobclixBannerAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kBannerAd];
    mobclixBannerAd.delegate = self;
    [self.currentAdsBucketArray addObject:mobclixBannerAd];
    
    GenericAd *mobclixFullScreenAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kFullScreenAd];
    mobclixFullScreenAd.delegate = self;
    [self.currentAdsBucketArray addObject:mobclixFullScreenAd];
    
    if ([self.adRequestQueue count] >= 1) {
        [self processAdQueue];
    }
}
+ (UIViewController *)getRootViewController{
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

/**
 @brief returns the if device is a simulator or not
 @param None
 */
-(BOOL)isSimulator
{
    NSRange textRange;
    textRange =[[UIDevice currentDevice].model rangeOfString:@"simulator"];
    if(textRange.location != NSNotFound)
    {
        return NO;
    }else
        return YES;
}
- (ConnectionStatus)isReachableVia{
    Reachability *r = [Reachability reachabilityWithHostName:@"http://www.apple.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == ReachableViaWiFi)
        return kWifiAvailable;
    else if (internetStatus == ReachableViaWWAN)
        return kWANAvailable;
    else
        return kNotReachable;
}

#pragma mark -
#pragma mark RevMob Ads
- (void) giveMeFullScreenRevMobAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    [[RevMobAds session] showFullscreen];
}
- (void) giveMeBannerRevMobAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    [[RevMobAds session] showBanner];
}
- (void) giveLinkRevMobAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    [[RevMobAds session] openAdLinkWithDelegate:nil];
}


#pragma mark -
#pragma mark General Methods
- (void)initializeAdNetworks{
    
    self.haveAdNetworksInitialized = NO;
    self.adRequestQueue = [[SNQueue alloc] init];
    
    NSBlockOperation *startRevMobAdsOperation = [NSBlockOperation blockOperationWithBlock:^{
       // [self startRevMob];
        /**
         Rev Mob Initialization Crashes if made on a background thread
         Screenshot
         https://www.evernote.com/shard/s51/sh/bcfeb98f-87f0-441a-a029-f1ecb4dc76d2/ab6ccc7e864ed966e6db7a102ec5eebe
         Their change log states as of 10th 2013 Feburary that they fixed the issue
         https://www.evernote.com/shard/s51/sh/984f0b11-4ea1-474a-86f0-3e915f98da4d/cb33358bbb8011f5a2f1f5475e7d028d
         But it still doesnt work.
         Once in future releases if this fixed just comment out everything and leave simple [self startRevMob];
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startRevMob];
        });
    }];
    [startRevMobAdsOperation setQueuePriority:NSOperationQueuePriorityHigh];
    [startRevMobAdsOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    NSBlockOperation *startChartBoostAdsOperation = [NSBlockOperation blockOperationWithBlock:^{
           //[self startChartBoost];
        /**
         Chartboost if initialised on background thread automatically calls didFailToLoadInterstitial:
         Which is very wiered.
         Chartboosts tech support for now recommends to wrap everything within main dispatch queue in GCD
         in other words run on main thread.
         https://www.evernote.com/shard/s51/sh/b44435f4-49ae-498d-898f-1497d223152e/724c886f1abb09016c3bc4178e33ef28
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startChartBoost];
        });
    }];
    [startChartBoostAdsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    [startChartBoostAdsOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    NSBlockOperation *startMobClixAdsOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self startMobclix];
    }];
    [startMobClixAdsOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    
    NSBlockOperation *startPlayHavenAdsOperation = [NSBlockOperation blockOperationWithBlock:^{
        [[PHPublisherOpenRequest requestForApp:kPlayHavenAppToken secret:kPlayHavenSecret] send];
    }];
    [startPlayHavenAdsOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    
    NSBlockOperation *startTapJoyOperation = [NSBlockOperation blockOperationWithBlock:^{
        [TapjoyConnect requestTapjoyConnect:kTapJoyAppID secretKey:kTapJoySecretKey];
    }];
    [startTapJoyOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    
    NSOperationQueue *adNetwroksInitializationQueue = [[NSOperationQueue alloc] init];
    [adNetwroksInitializationQueue addOperation:startChartBoostAdsOperation];
    [adNetwroksInitializationQueue addOperation:startPlayHavenAdsOperation];
    [adNetwroksInitializationQueue addOperation:startRevMobAdsOperation];
    [adNetwroksInitializationQueue addOperation:startMobClixAdsOperation];
    [adNetwroksInitializationQueue addOperation:startTapJoyOperation];
    

    
    if (self.myConnectionStatus == kWANAvailable)
        [adNetwroksInitializationQueue setMaxConcurrentOperationCount:2];
    else if (self.myConnectionStatus == kWifiAvailable)
        [adNetwroksInitializationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
}

- (void)addAdRequestToQueue:(SEL)selector{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.adRequestQueue push:[NSValue valueWithPointer:selector]];
    NSLog(@"Contents of queue %@", self.adRequestQueue);
}

-(void)processAdQueue{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (![self.adRequestQueue count] >= 1) {
        return;
    }
    NSOperationQueue *adProcessQueue = [[NSOperationQueue alloc] init];
    for (int i = 0; i <= [self.adRequestQueue count]; i++) {
        SEL selector = [[self.adRequestQueue pop] pointerValue];
        NSAssert(selector, @"Selector cannot be nil");
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:selector object:nil];
        [adProcessQueue addOperation:operation];
        [operation release];
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    NSLog(@"%s", __PRETTY_FUNCTION__);
   // NSLog(@"object %@", change);
    if ([keyPath isEqualToString:@"isFinished"]) {
        callBackCount++;
        if (callBackCount >= kNumberOfAdNetworks) {
            //[self fetchAds];
            /**
             Again RevMob is bit of a bitch crashing on other threads
             Once they fix it remove all this code and leave [self fetchAds];
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchAds];
                self.haveAdNetworksInitialized = YES;
            });
            
        }
    }
}

-(void)startMobclix {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [Mobclix startWithApplicationId:MOBCLIX_ID];
      //  [Mobclix startWithApplicationId:@"insert-your-application-key"];
    });
}

- (void)startChartBoost{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    Chartboost *cb = [Chartboost sharedChartboost];
    //cb.delegate = self;
    cb.appId = ChartBoostAppID;
    cb.appSignature = ChartBoostAppSignature;
    [cb cacheInterstitial];
    [cb cacheMoreApps];
    cb.timeout = 10;
    [cb startSession];
    self.chartBoost = cb;
}


- (void)startRevMob{
    [RevMobAds startSessionWithAppID: kRevMobId];
    [RevMobAds session].connectionTimeout = 10;
//    [RevMobAds session].testingMode = RevMobAdsTestingModeWithAds;
//    }
}

- (void)loadAdWithLowerPriorityThanPreviousAd:(GenericAd*)previousFailedAd{
    switch (previousFailedAd.adType) {
        case kBannerAd:
            [self loadBannerAdWithLowerPriorityhanPreviousAd:previousFailedAd];
            break;
        case kFullScreenAd:
            [self loadFullscreenAdWithLowerPriorityThanPreviousAd:previousFailedAd];
            break;
        case kLinkAd:
            [self loadLinkAdWithLowerPriorityThanPreviousAd:previousFailedAd];
        default:
            break;
    }
}

- (void)loadBannerAdWithLowerPriorityhanPreviousAd:(GenericAd*)previousFailedAd{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.currentBannerAdIndex == [self.sortedBannerAdsArray count] - 1) {
        [self failGracefully:previousFailedAd];
        self.currentBannerAdIndex = 0;
    }else{
        GenericAd *genericAd = [self.sortedBannerAdsArray objectAtIndex:self.currentBannerAdIndex + 1];
        if (!genericAd) {
            [self loadSortedBannerAdsArray];
            @try {
                genericAd = [self.sortedBannerAdsArray objectAtIndex:self.currentBannerAdIndex + 1];
            }
            @catch (NSException *exception) {
                [self failGracefully:previousFailedAd];
            }            
        }
        [genericAd showBannerAd];
        self.genericAd = genericAd;
        self.currentBannerAdIndex++;
    }
}

- (void)loadFullscreenAdWithLowerPriorityThanPreviousAd:(GenericAd*)previousFailedAd{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.currentSortedFullScreenAdIndex == [self.sortedFullScreenAdsArray count] - 1) {
        [self failGracefully:previousFailedAd];
        self.currentSortedFullScreenAdIndex = 0;//Reset the counter back to ZERO else it would keep failing
    }else{
        GenericAd *genericAd = [self.sortedFullScreenAdsArray objectAtIndex:self.currentSortedFullScreenAdIndex + 1];
       // NSAssert(genericAd, @"Ad cannot be NULL");
        if (!genericAd) {
            [self loadSortedFullScreenAdsArray];
            genericAd = [self.sortedFullScreenAdsArray objectAtIndex:self.currentSortedFullScreenAdIndex + 1];
        }
        genericAd.delegate = self;
        [genericAd showFullScreenAd];
        self.currentSortedFullScreenAdIndex++;
    }
}

- (void)loadSortedFullScreenAdsArray{
    NSMutableArray *fullScreenAdsInBucket;
    
    fullScreenAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kFullScreenAd];
    [fullScreenAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [fullScreenAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    if ([self.currentAdsBucketArray count] >= 1) {//Check Ad Bucket is not empty
        for (GenericAd *genAd in sortedArray) {
            NSLog(@"Priority is %d", genAd.adPriority);
        }
    }
    self.sortedFullScreenAdsArray = sortedArray;
}

- (void)loadSortedBannerAdsArray{
    NSMutableArray *bannerAdsInBucket;
    
    bannerAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kBannerAd];
    [bannerAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [bannerAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    self.sortedBannerAdsArray = sortedArray;

}
-(void)loadLinkAdWithLowerPriorityThanPreviousAd:(GenericAd*)previousFailedAd{
     [self failGracefully:previousFailedAd];
}


- (void)failGracefully:(GenericAd*)previousAd{
    //There is nothing graceful than doing nothing
    NSLog(@"All attempts to load Ad failed");
    switch (previousAd.adType) {
        case kBannerAd:
            if ([self.delegate respondsToSelector:@selector(bannerAdDidFailToLoad)]) {
                [self.delegate bannerAdDidFailToLoad];
            }
            break;
        case kFullScreenAd:
            if ([self.delegate respondsToSelector:@selector(fullScreenAdDidFailToLoad)]) {
                [self.delegate fullScreenAdDidFailToLoad];
            }
            break;
        case kLinkAd:
            if ([self.delegate respondsToSelector:@selector(linkAdDidFailToLoad)]) {
                [self.delegate linkAdDidFailToLoad];
            }
            //[self loadLinkAdWithLowerPriority];
        default:
            NSLog(@"Ad Type undefined");
            break;
    }
}

- (void) giveMeBannerAd{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *ad;
    NSMutableArray *bannerAdsInBucket;
  
    bannerAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kBannerAd];
    [bannerAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [bannerAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    self.sortedBannerAdsArray = sortedArray;
    ad = [bannerAdsInBucket objectAtIndex:0];
    self.genericAd = ad;
    self.genericAd.delegate = self;
    if ([ad respondsToSelector:@selector(showBannerAd)]) {
        [ad showBannerAd];
    }
    
    self.currentBannerAdIndex = 0;
}

- (void) giveMeBannerAdAtTop{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *ad;
    NSMutableArray *bannerAdsInBucket;
    
    bannerAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kBannerAd];
    [bannerAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [bannerAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    self.sortedBannerAdsArray = sortedArray;
    ad = [bannerAdsInBucket objectAtIndex:0];
    self.genericAd = ad;
    self.genericAd.delegate = self;
    if ([ad respondsToSelector:@selector(showBannerAd)]) {
        [ad showBannerAdAtTop];
    }
    
    self.currentBannerAdIndex = 0;
}
- (void) giveMeFullScreenAd{
    
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *ad;
    NSMutableArray *fullScreenAdsInBucket;
   
    fullScreenAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kFullScreenAd];
    [fullScreenAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [fullScreenAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    if ([self.currentAdsBucketArray count] >= 1) {//Check Ad Bucket is not empty
        for (GenericAd *genAd in sortedArray) {
            NSLog(@"Priority is %d", genAd.adPriority);
            NSLog(@"Ad Network Type is %d", genAd.adNetworkType);
        }
    }
    self.sortedFullScreenAdsArray = sortedArray;
    ad = [fullScreenAdsInBucket objectAtIndex:0];
    if ([ad respondsToSelector:@selector(showFullScreenAd)]) {
        ad.delegate = self;
        [ad showFullScreenAd];
    }
    self.currentSortedFullScreenAdIndex = 0;
}
- (void) giveMeLinkAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *ad;
    NSMutableArray *bannerAdsInBucket;
    
    bannerAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kLinkAd];
    [bannerAdsInBucket filterUsingPredicate:predicate];
    ad = [bannerAdsInBucket objectAtIndex:0];
    [ad showLinkButtonAd];
    //[bannerAdsInBucket release];
}

- (void)giveMeGameOverAd{
    [self giveMeFullScreenAd];
}

- (void)giveMeThirdGameOverAd{

    gameOverCount++;
    NSLog(@"game over counter %d", gameOverCount);
    if (gameOverCount %3 == 0){
        [self giveMeFullScreenAd];
    }
}

- (void)giveMeBootUpAd{
    [self giveMeFullScreenAd];
}
- (void)giveMeWillEnterForegroundAd{
    [[PHPublisherOpenRequest requestForApp:kPlayHavenAppToken secret:kPlayHavenSecret] send];
    [self giveMeFullScreenAd];
}
-(void) giveMePaidFullScreenAd{
    [self giveMeFullScreenChartBoostAd];
}

- (void) hideBannerAd{
    if (self.genericAd.adNetworkType == kRevMob) {
        [self.genericAd hideBannerAd];//Hide RevMob
    }else{
        [self.genericAd hideAd];//MobClix hide Ad
    }
    //[self.genericAd hideAd];
}

#pragma mark -
#pragma mark Charboost Ads
- (void) giveMeFullScreenChartBoostAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.chartBoost.delegate = nil;
        [self.chartBoost showInterstitial];
    });
    
}
- (void)giveMeMoreAppsAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    [self.chartBoost showMoreApps];
}
- (void) giveMeMoreAppsChartBoostAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    [self.chartBoost showMoreApps];
}
#pragma mark Delegate Methods


#pragma mark -
#pragma mark Mobclix delegates
- (void)giveMeFullScreenMobClixAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kFullScreenAd];
    [genericAd showFullScreenAd];
    [genericAd release];
}

- (void)giveMeBannerMobclixAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kBannerAd];
    [genericAd showBannerAd];
    [genericAd release];
}

#pragma mark -
#pragma mark Generic Ad Delegates
- (void)revMobFullScreenDidFailToLoad:(GenericAd *)ad{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadFullscreenAdWithLowerPriorityThanPreviousAd:ad];
    if ([self.delegate respondsToSelector:@selector(revMobFullScreenDidFailToLoad)]) {
        [self.delegate revMobFullScreenDidFailToLoad];
    }
}
- (void)mobClixFullScreenDidFailToLoad:(GenericAd *)ad{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadFullscreenAdWithLowerPriorityThanPreviousAd:ad];
    if ([self.delegate respondsToSelector:@selector(mobClixFullScreenDidFailToLoad)]) {
        [self.delegate mobClixFullScreenDidFailToLoad];
    }
}
- (void)revMobBannerDidFailToLoad:(GenericAd *)ad{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadBannerAdWithLowerPriorityhanPreviousAd:ad];
    //[self.delegate revMobBannerDidFailToLoad];
}

- (void)revMobBannerDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(revMobBannerDidLoad)]) {
        [self.delegate revMobBannerDidLoad];
    }
    if ([self.delegate respondsToSelector:@selector(bannerAdDidLoad)]) {
        [self.delegate bannerAdDidLoad];
    }
}
- (void)mobClixBannerDidFailToLoadBannerAd:(GenericAd *)ad{
    [self loadBannerAdWithLowerPriorityhanPreviousAd:ad];
}
- (void)mobClixBannerDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(bannerAdDidLoad)]) {
        [self.delegate bannerAdDidLoad];
    }
}

- (void)chartBoostFullScreenDidFailToLoad:(GenericAd *)ad{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadFullscreenAdWithLowerPriorityThanPreviousAd:ad];
    if ([self.delegate respondsToSelector:@selector(chartBoostFullScreenDidFailToLoad)]) {
        [self.delegate chartBoostFullScreenDidFailToLoad];
    }
}

- (void)revMobFullScreenDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(fullScreenAdDidLoad)]) {
        [self.delegate fullScreenAdDidLoad];
    }
}

- (void)chartBoostFullScreenDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(fullScreenAdDidLoad)]) {
        [self.delegate fullScreenAdDidLoad];
    }
}

- (void)mobClixFullScreenDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(fullScreenAdDidLoad)]) {
        [self.delegate fullScreenAdDidLoad];
    }
}

- (void)playHavenFullScreenDidLoadAd:(GenericAd *)ad{
    if ([self.delegate respondsToSelector:@selector(playHavenFullScreenDidLoad)]) {
        [self.delegate playHavenFullScreenDidLoad];
    }

}
- (void)playHavenFullScreenDidFailToLoad:(GenericAd *)ad{
    [self loadFullscreenAdWithLowerPriorityThanPreviousAd:ad];
    if ([self.delegate respondsToSelector:@selector(playHavenFullScreenDidFailToLoad)]) {
        [self.delegate playHavenFullScreenDidFailToLoad];
    }
    
}
@end
