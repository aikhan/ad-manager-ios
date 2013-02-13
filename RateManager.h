//
//  RateManager.h
//  Alien Tower
//
//  Created by Asad Khan on 13/02/2013.
//
//

#import "SNManager.h"
#import <Foundation/Foundation.h>

@interface RateManager : SNManager <UIAlertViewDelegate>

- (void)showReviewApp;
+ (RateManager *)sharedManager;

@end
