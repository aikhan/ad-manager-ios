//
//  LocalNotificationManager.m
//  Alien Tower
//
//  Created by Asad Khan on 07/02/2013.
//
//

#import "LocalNotificationManager.h"

@implementation LocalNotificationManager

@synthesize message = _message;

-(id)initWithMessage:(NSString*)message{
    self = [super init];
	if(self !=nil){
        NSArray *dayArray = [[NSArray alloc] init];
        dayArray = @[@3, @6, @9, @12, @15, @18, @21, @24, @27, @30, @33, @36, @39, @42, @45, @48, @51, @54, @57, @60];
        _message = message;
        [self scheduleNotifications:nil andDaysArray:dayArray];
    }
    return self;
}
-(id)initWithDayIntervalArray: (NSArray*)daysArray withText: (NSString*)message andSoundFile: (NSString*)soundFileName{
    self = [super init];
	if(self !=nil){
        [self scheduleNotifications:soundFileName andDaysArray:daysArray];
        _message = message;
    }
    return self;
}
-(void) scheduleNotifications:(NSString *)soundFileName andDaysArray:(NSArray*)daysArray{

	NSLog(@"scheduleAlarm");
    [daysArray retain];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    Class cls = NSClassFromString(@"UILocalNotification");
    if (cls != nil) {
		
        UILocalNotification *notif = [[cls alloc] init];
        notif.fireDate = [NSDate dateWithTimeInterval:60.0f*60.0f*24.0f*3.0f sinceDate:[NSDate date]];
        notif.timeZone = [NSTimeZone defaultTimeZone];
        notif.alertAction = @"PLAY";
        
        notif.alertBody = self.message;//@"Played Alien Tower lately!  Can you stack aliens without falling over?";
        if (soundFileName && ![soundFileName isEqualToString:@""]) {
            notif.soundName = soundFileName;
        }else{
            notif.soundName = UILocalNotificationDefaultSoundName;
        }
        notif.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        for(NSNumber *number in daysArray){
            notif.fireDate = [NSDate dateWithTimeInterval:60.0f*60.0f*24.0f*[number floatValue] sinceDate:[NSDate date]];
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        }
        
        [notif release];
    }
}


/*
 * Please Beware you cannot schedule not more than 64 notifications at one time
 * If there are more notifications and you also schedule testNotifications the
 * old notifications will get truncated.
 * So to be on safe side dont use this code in prodeuction code.
*/
- (void)testNotificationsSecondsWithSoundFileName:(NSString *)soundFileName andMessage:(NSString*)message{
   // [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    Class cls = NSClassFromString(@"UILocalNotification");
    if (cls != nil) {
		
        UILocalNotification *notif = [[cls alloc] init];
        notif.fireDate = [NSDate dateWithTimeInterval:60.0f*60.0f*24.0f*3.0f sinceDate:[NSDate date]];
        notif.timeZone = [NSTimeZone defaultTimeZone];
        notif.alertAction = @"PLAY";
        
        notif.alertBody = self.message;//@"Played Alien Tower lately!  Can you stack aliens without falling over?";
        if (soundFileName && ![soundFileName isEqualToString:@""]) {
            notif.soundName = soundFileName;
        }else{
            notif.soundName = UILocalNotificationDefaultSoundName;
        }
        notif.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        NSArray *dayArray = [[NSArray alloc] init];
        dayArray = @[@3, @6, @9, @12, @15, @18, @21, @24, @27, @30, @33, @36, @39, @42, @45, @48, @51, @54, @57, @60];
        for(NSNumber *number in dayArray){
            notif.fireDate = [NSDate dateWithTimeInterval:[number floatValue] sinceDate:[NSDate date]];
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        }
        
        [notif release];
    }
}

- (void)dealloc{
    [_message release];
    [super dealloc];
}
@end
