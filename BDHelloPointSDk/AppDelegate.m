//
//  AppDelegate.m
//  BDHelloPointSDk
//
//  Created by Neha  on 23/4/19.
//  Copyright © 2019 Bluedot. All rights reserved.
//

#import "AppDelegate.h"
@import UserNotifications;
@import BDPointSDK;
@import PushIOManager;


@interface AppDelegate () <BDPGeoTriggeringEventDelegate>

@property (nonatomic) NSDateFormatter    *dateFormatter;
@property (nonatomic) UIAlertController  *userInterventionForBluetoothDialog;
@property (nonatomic) UIAlertController  *userInterventionForLocationServicesNeverDialog;
@property (nonatomic) UIAlertController  *userInterventionForLocationServicesWhileInUseDialog;
@property (nonatomic) UIAlertController  *userInterventionForPowerModeDialog;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //Assign the delegates for session handling and location updates to this class.
    BDLocationManager.instance.geoTriggeringEventDelegate = self;
    
    // Configure the Oracle Responsys SDK
#ifdef DEBUG
    [[PushIOManager sharedInstance] setLoggingEnabled:YES];
    [[PushIOManager sharedInstance] setLogLevel:PIOLogLevelInfo]; //PIOLogLevelWarn or PIOLogLevelError
#else
    [[PushIOManager sharedInstance] setLoggingEnabled:NO];
#endif
    
#ifdef DEBUG
    [PushIOManager sharedInstance].configType = PIOConfigTypeDebug; //load pushio_config_debug.json
#else
    [PushIOManager sharedInstance].configType = PIOConfigTypeRelease;//load pushio_config.json
#endif
    
    // Configure the Oracle Responsys SDK. Please make sure your `config.json` files are in the app bundle.
    NSString *configName = @"config.json";
#ifdef DEBUG
    configName = @"pushio_config_debug.json";  // (Optional) If you want to configure app for iOS Development/Sandbox Pushs.
#endif

    [[PushIOManager sharedInstance] configureWithFileName:configName completionHandler:^(NSError *configError, NSString *response) {
        if (configError != nil) {
            NSLog(@"Unable to configure PushIOManager SDK, reason: %@", configError.description);
            return;
        } else {
            NSLog(@"PushIOManager SDK Configured Successfully");
        }

        // Requests a device token from Apple
        [[PushIOManager sharedInstance] registerForAllRemoteNotificationTypes:^(NSError *error, NSString *deviceToken) {
             if (nil == error) {
                 
                 // Register application with Responsys server. This API is responsible to send registration signal to Responsys server.
                 // This API sends all the values configured on SDK to server
                 NSError *regTrackError = nil;
                 [[PushIOManager sharedInstance] registerApp:&regTrackError completionHandler:^(NSError *regAppError, NSString *response) {
                      if (nil == regAppError) {
                          NSLog(@"Application registered successfully!");
                      } else {
                          NSLog(@"Unable to register application, reason: %@", regAppError.description);
                      }
                  }];
                 if (nil == regTrackError) {
                     NSLog(@"Registration locally stored successfully.");
                 } else {
                     NSLog(@"Unable to store registration, reason: %@", regTrackError.description);
                 }
             }
         }];
    }];
    
    // Call the didFinishLaunching of SDK at end
    [[PushIOManager sharedInstance] didFinishLaunchingWithOptions:launchOptions];
    
    // Override point for customization after application launch.
    [UNUserNotificationCenter currentNotificationCenter].delegate= self;
    
    //request authorization for notification
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!granted) {
                                  NSLog(@"Notification error");
                              }
                          }];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Conform to BDPGeoTriggering protocol - call-backs which Point SDK makes to inform the Application of geo-triggering related events

- (void)onZoneInfoUpdate:(NSSet<BDZoneInfo *> *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
}

- (void)didEnterZone:(BDZoneEntryEvent *)enterEvent {
    NSLog(@"didEnterZone %@", enterEvent.zone.name);
    
    PIOGeoRegion *geoRegion = [[PIOGeoRegion alloc] initWithGeofenceId:enterEvent.fence.ID
        geofenceName:enterEvent.fence.name
        speed:enterEvent.location.speed
        bearing:enterEvent.location.bearing
        source:@"BDPointSDK"
        zoneId:enterEvent.zone.ID
        zoneName:enterEvent.zone.name
        dwellTime:0
        extra:enterEvent.zone.customData];
  
    [[PushIOManager sharedInstance] didEnterGeoRegion:geoRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            NSLog(@"Geofence Entry Event triggered successfully");
        } else {
            NSLog(@"Unable to send Geofence Entry Event, reason: %@", error.description);
        }
    }];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *formattedDate = [_dateFormatter stringFromDate: enterEvent.location.timestamp];
    
    NSString *message = [NSString stringWithFormat: @"You have checked into fence '%@' in zone '%@', at %@",enterEvent.fence.name, enterEvent.zone.name, formattedDate];
    
    [self showAlert: message];
}

- (void)didExitZone:(BDZoneExitEvent *)exitEvent {
    NSLog(@"didExitZone %@", exitEvent.zone.name);
          
    PIOGeoRegion *geoRegion = [[PIOGeoRegion alloc]
        initWithGeofenceId:exitEvent.fence.ID
        geofenceName:exitEvent.fence.name
        speed:0.0
        bearing:0.0
        source:@"BDPointSDK"
        zoneId:exitEvent.zone.ID
        zoneName:exitEvent.zone.name
        dwellTime:exitEvent.duration
        extra:exitEvent.zone.customData];
    
    [[PushIOManager sharedInstance] didExitGeoRegion:geoRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            NSLog(@"Geofence Exit Event triggered successfully");
        } else {
            NSLog(@"Unable to send Geofence Exit Event, reason: %@", error.description);
        }
    }];
    
    NSString *message = [NSString stringWithFormat: @"You left '%@' in zone '%@' after %lu minutes",exitEvent.fence.name, exitEvent.zone.name, (unsigned long)exitEvent.duration];
    
    [self showAlert: message];
}

#pragma mark - Private

- (void)showAlert: (NSString *)message {
    UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
    
    switch (applicationState) {
            // In the foreground: display notification directly to the user
        case UIApplicationStateActive: {
            UIAlertController *alertController = [ UIAlertController alertControllerWithTitle:@"Application notification"
                                                                                      message:message
                                                                               preferredStyle:UIAlertControllerStyleAlert ];
            
            UIAlertAction *OK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil ];
            
            [alertController addAction:OK];
            
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            break;
        }
            
            // If not in the foreground: deliver a local notification
        default: {
            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
            content.title = @"BDPoint Notification";
            content.body = message;
            content.sound = [UNNotificationSound defaultSound];
            
            NSString *identifier = @"BDPointNotification";
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:nil];
            
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error != nil) {
                    NSLog(@"Notification error: %@",error);
                }
            }];
            break;
        }
    }
}

#pragma mark - AppDelegates Push Notification Service

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *)deviceToken {
    [[PushIOManager sharedInstance]  didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[PushIOManager sharedInstance]  didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [[PushIOManager sharedInstance] didReceiveRemoteNotification:userInfo
                                           fetchCompletionResult:UIBackgroundFetchResultNewData
                                          fetchCompletionHandler:completionHandler];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [[PushIOManager sharedInstance] openURL:url options:options];
    return YES;
}

-(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler {
    
    [[PushIOManager sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response
                                     withCompletionHandler:completionHandler];
}

-(void) userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    [[PushIOManager sharedInstance] userNotificationCenter:center
                                   willPresentNotification:notification
                                     withCompletionHandler:completionHandler];
}

@end
