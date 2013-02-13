//
//  RateManager.m
//  Alien Tower
//
//  Created by Asad Khan on 13/02/2013.
//
//

#import "RateManager.h"

static NSUInteger gameOverCountForRating = 0;

@interface RateManager()

- (BOOL)hasAppBeenRated;
- (void)setAppRated;
- (void)rateApp;

@end

@implementation RateManager
#pragma mark -
#pragma mark Singleton Methods

static RateManager *sharedManager = nil;

+ (RateManager*)sharedManager{
    if (sharedManager != nil)
    {
        return sharedManager;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    static dispatch_once_t safer;
    dispatch_once(&safer, ^(void)
                  {
                      sharedManager = [[RateManager alloc] init];
                      
                  });
#else
    @synchronized([RateManager class])
    {
        if (sharedManager == nil)
        {
            sharedManager = [[RateManager alloc] init];
            
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
        
    }
	return self;
	
}//end init

- (void)dealloc {
	NSLog(@"dealloc called");
    return;
    [super dealloc];
}


- (BOOL)hasAppBeenRated{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults boolForKey:@"isRated"];
}

- (void)setAppRated{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setBool:YES forKey:@"isRated"];
    [standardUserDefaults synchronize];
}

- (void)showReviewApp{
    gameOverCountForRating++;
    if(gameOverCountForRating % 3 == 2)
    {
        if (![self hasAppBeenRated]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please review this great app! " delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            alert.tag = 2;
            alert.delegate = self;
            [alert show];
            [alert release];
        }
    }
}
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == 2)
	{// rate app
        
        [self rateApp];
	}
}

- (void)rateApp{
    [self setAppRated];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kRateURL]];
}

@end
