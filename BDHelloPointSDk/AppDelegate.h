//
//  AppDelegate.h
//  BDHelloPointSDk
//
//  Created by Neha  on 23/4/19.
//  Copyright © 2019 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>

//Import PushIOManager
#import <PushIOManager/PushIOManager.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

