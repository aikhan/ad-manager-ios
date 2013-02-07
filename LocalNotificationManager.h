//
//  LocalNotificationManager.h
//  Alien Tower
//
//  Created by Asad Khan on 07/02/2013.
//
//

#import <Foundation/Foundation.h>

@interface LocalNotificationManager : NSObject


@property(nonatomic, strong)NSString *message;

-(id)initWithMessage:(NSString*)message;
-(id)initWithDayIntervalArray: (NSArray*)daysArray withText: (NSString*)message andSoundFile: (NSString*)soundFileName;
-(void) scheduleNotifications:(NSString *)soundFileName andDaysArray:(NSArray*)daysArray;



/* CAUTION
 * Please Beware you cannot schedule not more than 64 notifications at one time
 * If there are more notifications and you also schedule testNotifications the
 * old notifications will get truncated.
 * So to be on safe side dont use this code in production code.
 */
- (void)testNotificationsSecondsWithSoundFileName:(NSString *)soundFileName andMessage:(NSString*)message;


@end
