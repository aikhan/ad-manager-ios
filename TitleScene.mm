//
//  TitleScene.mm
//  towerGame
//
//  Created by KCU on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "RestoreIAPScene.h"
#import "TitleScene.h"
#import "BeginScene.h"
#import "SettingScene.h"
#import "ScoreScene.h"
#import "CCButton.h"
#import "CCZoomButton.h"
#import "UmbObject.h"
#import "AnimationManager.h"
#import "towerGameAppDelegate.h"
#import "SettingsManager.h"
#import <RevMobAds/RevMobAds.h>
#import "AdsManager.h"
#import "RootViewController.h"
#import "MKStoreManager.h"
#import "AppSpecificValues.h"
#import "SNAdsManager.h"
@implementation TitleScene


+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	TitleScene *layer = [TitleScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    towerGameAppDelegate *mainDelegate = (towerGameAppDelegate *)[[UIApplication sharedApplication]delegate];
    //if ( mainDelegate.m_showhint == 1 ) {
        mainDelegate.m_showhint =1;
    [[AdsManager sharedAdsManager]  hideAd];
    //}

	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) 
	{
		backManager = [BackgroundManager sharedBackgroundManager];
		resManager = [ResourceManager sharedResourceManager]; 
		CCZoomButton* btnPlay = [[CCZoomButton alloc] initWithTarget:self
                                                            selector:@selector(goBeginSceneCallback:)
                                                         textureName: @"title_play"
                                                      selTextureName: @"title_play1"
                                                            textName: @""
                                                            position: (CGPointMake(ipx(170), ipy(160)))
                                                           afterTime:0.4f];
		[self addChild: btnPlay];
		
		CCZoomButton* btnScore = [[CCZoomButton alloc] initWithTarget:self
															 selector:@selector(goScoreSceneCallback:)
														  textureName: @"title_score"
													   selTextureName: @"title_score1"
															 textName: @""
															 position: (CGPointMake(ipx(170), ipy(240)))
															afterTime:0.6f];
		[self addChild: btnScore];
        
		CCZoomButton* btnSetting = [[CCZoomButton alloc] initWithTarget:self
                                                               selector:@selector(goSettingSceneCallback:)
                                                            textureName: @"title_setting"
                                                         selTextureName: @"title_setting1"
                                                               textName: @""
                                                               position: (CGPointMake(ipx(170), ipy(320)))
                                                              afterTime:0.8f];
		[self addChild: btnSetting];
        
        
        CCMenuItemImage *moreApps;
        moreApps = [CCMenuItemImage itemFromNormalImage:SHImageString(@"freegame-blue") selectedImage:SHImageString(@"freegame-blue") target:self selector:@selector(onMoreApps:)];
        
        CCMenu* moreAppsMenu = [CCMenu menuWithItems: moreApps, nil];
        moreAppsMenu.position = ccp((moreApps.boundingBox.size.width/2), (SCREEN_HEIGHT - moreApps.boundingBox.size.height/2));
        [self addChild:moreAppsMenu];
#ifdef FreeApp
        if (![SettingsManager sharedManager].hasInAppPurchaseBeenMade) {
            CCMenuItemImage *removeAds;
            removeAds = [CCMenuItemImage itemFromNormalImage:SHImageString(@"removeads") selectedImage:SHImageString(@"removeads") target:self selector:@selector(buyInApp)];
            
            CCMenu* removeAdsMenu = [CCMenu menuWithItems: removeAds, nil];
            removeAdsMenu.position = ccp(ipx(100), ipy(50));
            removeAdsMenu.tag = 20;
            
            [self addChild:removeAdsMenu];
            
            CCMenuItemImage *restore;
            restore = [CCMenuItemImage itemFromNormalImage:SHImageString(@"restore") selectedImage:SHImageString(@"restore") target:self selector:@selector(restoreiap:)];
            
            CCMenu* restoreMenu = [CCMenu menuWithItems: restore, nil];
            restoreMenu.position = ccp(ipx(245), ipy(50));
            restoreMenu.tag = 21;
            [self addChild:restoreMenu];
        }
        //[[SNAdsManager sharedManager] giveMeBannerMobclixAd];
#endif
        
       /* if ([SettingsManager sharedManager].hasInAppPurchaseBeenMade) {
            [[SNAdsManager sharedManager] hideBannerAd];
           
        }else{
            [[SNAdsManager sharedManager] giveMeBannerAd];
        }
        */
	}
	return self;
}

-(void)onMoreApps:(id)sneder
{
    //towerGameAppDelegate* del = (towerGameAppDelegate*)[UIApplication sharedApplication].delegate;
    //[del showMoreApps];
    [[SNAdsManager sharedManager] giveMeMoreAppsAd];
}

- (void) goBeginSceneCallback: (id) sender
{
	CCScene* beginScene = [BeginScene node];
	[[CCDirector sharedDirector] replaceScene:beginScene];	
}

- (void) goScoreSceneCallback: (id) sender
{
    [(towerGameAppDelegate*)[[UIApplication sharedApplication] delegate] abrirLDB];
	//CCScene* scoreScene = [ScoreScene node];
	//[[CCDirector sharedDirector] replaceScene:scoreScene];	
}

- (void) goSettingSceneCallback: (id) sender
{
	CCScene* settingScene = [SettingScene node];
	[[CCDirector sharedDirector] replaceScene:settingScene];	
}

- (void) draw
{
	[backManager draw];
	//[backManager drawTitle: 0];
}

- (void) dealloc
{
	[super dealloc];
}

- (void) restoreiap: (id) sender

{
    CCScene* restoreIAPScene = [RestoreIAPScene node];
	[[CCDirector sharedDirector] replaceScene: restoreIAPScene];	
	//[super dealloc];
}

- (void)onEnterTransitionDidFinish{
    [[SNAdsManager sharedManager] hideBannerAd];
}

- (void)buyInApp{
#ifdef FreeApp
    //NSString *str = buyFullAppURL;
    
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    [[SettingsManager sharedManager].rootViewController showLoadingView];
    [[MKStoreManager sharedManager] buyFeature: featureAIdVar
                                    onComplete:^(NSString* purchasedFeature)
     {
         
         towerGameAppDelegate *mainDelegate = (towerGameAppDelegate *)[[UIApplication sharedApplication]delegate];
         
         mainDelegate.m_no_ads = NO;
         
         [[SettingsManager sharedManager].rootViewController hideLoadingView];
         NSLog(@"Purchased: %@", purchasedFeature);
         [SettingsManager sharedManager].hasInAppPurchaseBeenMade = YES;
         NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
         [standardUserDefaults setBool:[SettingsManager sharedManager].hasInAppPurchaseBeenMade forKey:@"inapp"];
         [standardUserDefaults synchronize];
         [[RevMobAds session] hideBanner];
        
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Purchase was successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         [alert show];
         [alert release];
         //CCMenu *menu = (CCMenu*)[self getChildByTag:20];
         [self removeChildByTag:21 cleanup:YES];
         [self removeChildByTag:20 cleanup:YES];
         
         //[self actionResume];
         //[m_spFire setVisible:NO];
         //[self gotoGameOverView];
         
         //  [self createAd];
         // remembering this purchase is taken care of by MKStoreKit.
     }
                                   onCancelled:^
     {
         NSLog(@"Something went wrong");
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         [alert show];
         [alert release];
         [[SettingsManager sharedManager].rootViewController hideLoadingView];
         // User cancels the transaction, you can log this using any analytics software like Flurry.
     }];
    
    
    
#endif
}

@end
