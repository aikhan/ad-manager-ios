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

@interface SNAdsManager()


@property (nonatomic, strong)NSArray *sortedBannerAdsArray;
@property (nonatomic, assign)NSUInteger currentBannerAdIndex;
@property (nonatomic, strong)NSArray *sortedFullScreenAdsArray;
@property (nonatomic, assign)NSUInteger currentSortedFullScreenAdIndex;

@property (nonatomic, assign)BOOL haveAdNetworksInitialized;
@property (nonatomic, strong)SNQueue *adRequestQueue;

- (void)loadAdWithLowerPriority;
- (void)loadBannerAdWithLowerPriority;
- (void)loadFullscreenAdWithLowerPriority;
- (void)loadLinkAdWithLowerPriority;
- (void)failGracefully;

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
    [self.currentAdsBucketArray addObject:chartBoostFullScreenAd];
    
    GenericAd *chartBoostMoreAppsAd = [[GenericAd alloc] initWithAdNetworkType:kChartBoost andAdType:kMoreAppsAd];
    [self.currentAdsBucketArray addObject:chartBoostMoreAppsAd];
    
    GenericAd *revMobBannerAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kBannerAd];
    [self.currentAdsBucketArray addObject:revMobBannerAd];
    
    GenericAd *revMobFullScreenAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kFullScreenAd];
    [self.currentAdsBucketArray addObject:revMobFullScreenAd];
    
    GenericAd *revMobLinkAd = [[GenericAd alloc] initWithAdNetworkType:kRevMob andAdType:kLinkAd];
    [self.currentAdsBucketArray addObject:revMobLinkAd];
    
    GenericAd *mobclixBannerAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kBannerAd];
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

- (void)revmobAdDidFailWithError:(NSError *)error{//Rev Mobs Delegate
    [self loadAdWithLowerPriority];
}
- (void)revMobFullScreenDidFailToLoad:(GenericAd *)ad{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadAdWithLowerPriority];
}

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
    [[RevMobAds session] openAdLinkWithDelegate:self];
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
    //startRevMobAdsOperation.
    [startRevMobAdsOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    NSBlockOperation *startChartBoostAdsOperation = [NSBlockOperation blockOperationWithBlock:^{
           //[self startChartBoost];
        /**
         Chartboost if initialised on background thread automatically calls didFailToLoadInterstitial:
         Which is very wiered.
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
    
    NSOperationQueue *adNetwroksInitializationQueue = [[NSOperationQueue alloc] init];
    [adNetwroksInitializationQueue addOperation:startChartBoostAdsOperation];
    [adNetwroksInitializationQueue addOperation:startRevMobAdsOperation];
    [adNetwroksInitializationQueue addOperation:startMobClixAdsOperation];

    
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
    for (int i = 0; i < [self.adRequestQueue count]; i++) {
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
    [Mobclix startWithApplicationId:MOBCLIX_ID];
   // [Mobclix startWithApplicationId:@"insert-your-application-key"];
}

- (void)startChartBoost{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    Chartboost *cb = [Chartboost sharedChartboost];
    cb.delegate = self;
    cb.appId = ChartBoostAppID;
    cb.appSignature = ChartBoostAppSignature;
    [cb cacheInterstitial];
    [cb cacheMoreApps];
    [cb startSession];
    self.chartBoost = cb;
}


- (void)startRevMob{
    [RevMobAds startSessionWithAppID:kRevMobId];
    if ([self isSimulator]) {
        [RevMobAds session].testingMode = RevMobAdsTestingModeWithAds;
    }
}

- (void)loadAdWithLowerPriority{
    switch (self.genericAd.adType) {
        case kBannerAd:
            [self loadBannerAdWithLowerPriority];
            break;
        case kFullScreenAd:
            [self loadFullscreenAdWithLowerPriority];
            break;
        case kLinkAd:
            [self loadLinkAdWithLowerPriority];
        default:
            break;
    }
}

- (void)loadBannerAdWithLowerPriority{
    if (self.currentBannerAdIndex == [self.sortedBannerAdsArray count] - 1) {
        [self failGracefully];
        self.currentBannerAdIndex = 0;
    }else{
        GenericAd *genericAd = [self.sortedBannerAdsArray objectAtIndex:self.currentBannerAdIndex + 1];
        [genericAd showBannerAd];
        self.currentBannerAdIndex++;
    }
}

- (void)loadFullscreenAdWithLowerPriority{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.currentSortedFullScreenAdIndex == [self.sortedFullScreenAdsArray count] - 1) {
        [self failGracefully];
        self.currentSortedFullScreenAdIndex = 0;//Reset the counter back to ZERO else it would keep failing
    }else{
        GenericAd *genericAd = [self.sortedFullScreenAdsArray objectAtIndex:self.currentSortedFullScreenAdIndex + 1];
        NSAssert(genericAd, @"Ad cannot be NULL");
        [genericAd showFullScreenAd];
        self.currentSortedFullScreenAdIndex++;
    }
}

-(void)loadLinkAdWithLowerPriority{
     [self failGracefully];
}


- (void)failGracefully{
    //There is nothing graceful than doing nothing
    NSLog(@"All attempts to load Ad failed");
   
}

- (void) giveMeBannerAd{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *ad;// = [[GenericAd alloc] initWithAdType:kBannerAd];
    NSMutableArray *bannerAdsInBucket;// = [[NSMutableArray alloc] init];
  
    bannerAdsInBucket = [self.currentAdsBucketArray mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adType == %d", kBannerAd];
    [bannerAdsInBucket filterUsingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"adPriority"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [bannerAdsInBucket sortedArrayUsingDescriptors:sortDescriptors];
    
    if ([self.currentAdsBucketArray count] >= 1) {//Check Ad Bucket is not empty
        for (GenericAd *genAd in sortedArray) {
            NSLog(@"Priority is %d", genAd.adPriority);
        }
    }
    self.sortedBannerAdsArray = sortedArray;
    ad = [bannerAdsInBucket objectAtIndex:0];
    if ([ad respondsToSelector:@selector(showBannerAd)]) {
        [ad showBannerAd];
    }
    self.genericAd = ad;
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
    [[RevMobAds session] openAdLinkWithDelegate:self];
}

- (void) hideBannerAd{
    if (self.genericAd.adNetworkType == kRevMob) {
        [[RevMobAds session] hideBanner];
    }else{
        [self.genericAd hideAd];//MobClix hide Ad
    }
}

#pragma mark -
#pragma mark Charboost Ads
- (void) giveMeFullScreenChartBoostAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    //self.chartBoost.delegate = nil;
    [self.chartBoost showInterstitial];
}

//TODO:If you call giveMeFullScreenChartBoostAd and Ad fails to load the app will not load another ad
//This is a known bug

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
- (void)didFailToLoadInterstitial:(NSString *)location{
    NSLog(@"%s", __PRETTY_FUNCTION__);
   // NSLog(@"%@",[NSThread callStackSymbols]);
    [self loadFullscreenAdWithLowerPriority];
}
- (BOOL)shouldDisplayLoadingViewForMoreApps{
    return YES;
}

#pragma mark -
#pragma mark Mobclix delegates

- (void)mobClixFullScreenDidFailToLoad:(GenericAd *)ad{
    [self loadFullscreenAdWithLowerPriority];
}
- (void)giveMeFullScreenMobClixAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kFullScreenAd];
    [genericAd showFullScreenAd];
}

- (void)giveMeBannerMobclixAd{
    if (!self.haveAdNetworksInitialized) {
        [self addAdRequestToQueue:_cmd];
        return;
    }
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kBannerAd];
    [genericAd showBannerAd];
}
@end
