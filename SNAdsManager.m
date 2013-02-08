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

@interface SNAdsManager()


@property (nonatomic, strong)NSArray *sortedBannerAdsArray;
@property (nonatomic, assign)NSUInteger currentBannerAdIndex;
@property (nonatomic, strong)NSArray *sortedFullScreenAdsArray;
@property (nonatomic, assign)NSUInteger currentSortedFullScreenAdIndex;

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
        
        if(self.myConnectionStatus == kNotReachable){
            [self initializeAdNetworks];
            [self fetchAds];
            //[self performSelector:@selector(initializeAdNetworks) withObject:nil afterDelay:0.1];
            //[self performSelector:@selector(fetchAds) withObject:nil afterDelay:0.4];
        }else{
        NSLog(@"!!!Offline!!!");
        }
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
    [[RevMobAds session] showFullscreen];
}
- (void) giveMeBannerRevMobAd{
    [[RevMobAds session] showBanner];
}
- (void) giveLinkRevMobAd{
    [[RevMobAds session] openAdLinkWithDelegate:self];
}


#pragma mark -
#pragma mark General Methods
- (void)initializeAdNetworks{
    
    [self startRevMob];
    [self startChartBoost];
    [self startMobclix];
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
    if (self.currentSortedFullScreenAdIndex == [self.sortedFullScreenAdsArray count] - 1) {
        [self failGracefully];
    }else{
        GenericAd *genericAd = [self.sortedBannerAdsArray objectAtIndex:self.currentBannerAdIndex + 1];
        [genericAd showBannerAd];
        self.currentBannerAdIndex++;
    }
}

- (void)loadFullscreenAdWithLowerPriority{
    if (self.currentSortedFullScreenAdIndex == [self.sortedFullScreenAdsArray count] - 1) {
        [self failGracefully];
    }else{
        GenericAd *genericAd = [self.sortedFullScreenAdsArray objectAtIndex:self.currentSortedFullScreenAdIndex + 1];
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
    GenericAd *ad;// = [[GenericAd alloc] initWithAdType:kBannerAd];
    NSMutableArray *fullScreenAdsInBucket;// = [[NSMutableArray alloc] init];
   
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
    [self.chartBoost showInterstitial];
}

- (void)giveMeMoreAppsAd{
    [self.chartBoost showMoreApps];
}
- (void) giveMeMoreAppsChartBoostAd{
    [self.chartBoost showMoreApps];
}
#pragma mark Delegate Methods
- (void)didFailToLoadInterstitial:(NSString *)location{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadFullscreenAdWithLowerPriority];
}

#pragma mark -
#pragma mark Mobclix delegates

- (void)mobClixFullScreenDidFailToLoad:(GenericAd *)ad{
    [self loadFullscreenAdWithLowerPriority];
}
- (void)giveMeFullScreenMobClixAd{
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kFullScreenAd];
    [genericAd showFullScreenAd];
}

- (void)giveMeBannerMobclixAd{
    GenericAd *genericAd = [[GenericAd alloc] initWithAdNetworkType:kMobiClix andAdType:kBannerAd];
    [genericAd showBannerAd];
}
@end
