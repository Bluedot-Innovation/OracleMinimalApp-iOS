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


@interface AppDelegate () <BDPSessionDelegate, BDPLocationDelegate>

@property (nonatomic) NSDateFormatter    *dateFormatter;
@property (nonatomic) UIAlertController  *userInterventionForBluetoothDialog;
@property (nonatomic) UIAlertController  *userInterventionForLocationServicesNeverDialog;
@property (nonatomic) UIAlertController  *userInterventionForLocationServicesWhileInUseDialog;
@property (nonatomic) UIAlertController  *userInterventionForPowerModeDialog;

@end

@implementation AppDelegate


NSString  *EXResponseError = @"BDResponseErrorInfoKeyName";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //Assign the delegates for session handling and location updates to this class.
    BDLocationManager.instance.sessionDelegate = self;
    BDLocationManager.instance.locationDelegate = self;
    
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
    
    NSString *apiKey = nil;
    NSString *accountToken = nil;
    
#ifdef DEBUG
    apiKey = @"PUSHIO-API-KEY"; //Copy the apiKey value from pushio_config_debug.json
    accountToken = @"PUSHIO-ACCOUNT-TOKEN"; //Copy the accountToken value from pushio_config_debug.json. Assign nil if no value available.
#else
    apiKey = @"PUSHIO-API-KEY"; //Copy the apiKey value from pushio_config.json.
    accountToken = @"PUSHIO-ACCOUNT-TOKEN";//Copy the accountToken value from pushio_config.json. Assign nil if no value available.
#endif
    
    NSError *error = nil;
    [[PushIOManager sharedInstance] configureWithAPIKey:apiKey accountToken:accountToken error:&error];
    if(nil == error)
    {
        NSLog(@"SDK Configured Successfully");
    }
    else
    {
        NSLog(@"Unable to configure SDK, reason: %@", error.description);
    }
    
    // Requests a device token from Apple
    [[PushIOManager sharedInstance] registerForAllRemoteNotificationTypes:^(NSError *error, NSString *deviceToken)
     {
         if (nil == error) {
             NSError *regTrackError = nil;
             [[PushIOManager sharedInstance] registerApp:&regTrackError completionHandler:^(NSError *regAppError, NSString *response)
              {
                  if (nil == regAppError){
                      NSLog(@"Application registered successfully!");
                  }else{
                      NSLog(@"Unable to register application, reason: %@", regAppError.description);
                  }
              }];
             if (nil == regTrackError) {
                 NSLog(@"Registration locally stored successfully.");
             }else{
                 NSLog(@"Unable to store registration, reason: %@", regTrackError.description);
             }
         }
     }];
    
    [[PushIOManager sharedInstance] didFinishLaunchingWithOptions:launchOptions];
    // Override point for customization after application launch.
    [UNUserNotificationCenter currentNotificationCenter].delegate= self;
    
    //request authorization for notification
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!granted) {
                                  NSLog(@"notification error");
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

//MARK:- Conform to BDPSessionDelegate protocol - Point SDK's session related callbacks

- (void)willAuthenticateWithApiKey: (NSString *)apiKey
{
    NSLog( @"Authenticating with Point sdk" );
}

- (void)authenticationWasSuccessful
{
    NSLog( @"Authenticated successfully with Point sdk" );
    [[PushIOManager sharedInstance] registerUserID:BDLocationManager.instance.installRef];
    
}

- (void)authenticationWasDeniedWithReason: (NSString *)reason
{
    NSLog( @"Authentication with Point sdk denied, with reason: %@", reason );
    
    UIAlertController *alertController = [ UIAlertController alertControllerWithTitle:
                                          @"Authentication Denied" message: reason
                                                                       preferredStyle: UIAlertControllerStyleAlert ];
    
    UIAlertAction *OK = [ UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleCancel handler: nil ];
    
    [ alertController addAction:OK ];
    
    [self.window.rootViewController presentViewController: alertController animated: YES completion: nil];
}

- (void)authenticationFailedWithError: (NSError *)error
{
    NSLog( @"Authentication with Point sdk failed, with reason: %@", error.localizedDescription );
    
    NSString  *title;
    NSString  *message;
    
    //  BDResponseError will be more conveniently exposed in the next version
    BOOL isConnectionError = ( error.userInfo[ EXResponseError ] == NSURLErrorDomain );
    
    if ( isConnectionError == YES )
    {
        title = @"No data connection?";
        message = @"Sorry, but there was a problem connecting to Bluedot servers.\n"
        "Please check you have a data connection, and that flight mode is disabled, and try again.";
    }
    else
    {
        title = @"Authentication Failed";
        message = error.localizedDescription;
    }
    
    UIAlertController *alertController = [ UIAlertController alertControllerWithTitle: title
                                                                              message: message
                                                                       preferredStyle: UIAlertControllerStyleAlert ];
    
    UIAlertAction *OK = [ UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleCancel handler: nil ];
    
    [ alertController addAction:OK ];
    
    [self.window.rootViewController presentViewController: alertController animated: YES completion: nil ];
}

- (void)didEndSession
{
    NSLog( @"Logged out" );
    [[PushIOManager sharedInstance] registerUserID:nil];
}

- (void)didEndSessionWithError: (NSError *)error
{
    NSLog( @"Logged out with error: %@", error.localizedDescription );
    
}

//MARK:- Conform to BDPLocationDelegate protocol - call-backs which Point SDK makes to inform the Application of location-related events

//MARK: This method is passed the Zone information utilised by the Bluedot SDK.
- (void)didUpdateZoneInfo: (NSSet *)zones
{
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zones.count );
    
}

//MARK: checked into a zone
//fence         - Fence triggered
//zoneInfo      - Zone information Fence belongs to
//location      - Geographical coordinate where trigger happened
//customData    - Custom data associated with this Custom Action

- (void)didCheckIntoFence: (BDFenceInfo *)fence
                   inZone: (BDZoneInfo *)zoneInfo
               atLocation: (BDLocationInfo *)location
             willCheckOut: (BOOL)willCheckOut
           withCustomData: (NSDictionary *)customData
{
    PIOGeoRegion *geoRegion = [[PIOGeoRegion alloc] initWithGeofenceId:fence.ID geofenceName:fence.name speed:location.speed bearing:location.bearing source:@"BDPointSDK" zoneId:zoneInfo.ID zoneName:zoneInfo.name dwellTime:0 extra:customData];
  
    [[PushIOManager sharedInstance] didEnterGeoRegion:geoRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            //Geofence Entry Event triggered successfully
        } else {
            NSLog(@"Unable to send Geofence Entry Event, reason: %@", error.description);
        }
    }];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *formattedDate = [ _dateFormatter stringFromDate: location.timestamp ];
    
    NSString *message = [ NSString stringWithFormat: @"You have checked into fence '%@' in zone '%@', at %@",fence.name, zoneInfo.name, formattedDate ];
    
    [ self showAlert: message ];
    
}

//MARK: Checked out from a zone
//fence             - Fence user is checked out from
//zoneInfo          - Zone information Fence belongs to
//checkedInDuration - Time spent inside the Fence in minutes
//customData        - Custom data associated with this Custom Action

- (void)didCheckOutFromFence: (BDFenceInfo *)fence
                      inZone: (BDZoneInfo *)zoneInfo
                      onDate: (NSDate *)date
                withDuration: (NSUInteger)checkedInDuration
              withCustomData: (NSDictionary *)customData
{
    PIOGeoRegion *geoRegion = [[PIOGeoRegion alloc] initWithGeofenceId:fence.ID geofenceName:fence.name speed:0.0 bearing:0.0 source:@"BDPointSDK" zoneId:zoneInfo.ID zoneName:zoneInfo.name dwellTime:checkedInDuration extra:customData];
    [[PushIOManager sharedInstance] didExitGeoRegion:geoRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            //Geofence Exit Event triggered successfully
        } else {
            NSLog(@"Unable to send Geofence Exit Event, reason: %@", error.description);
        }
    }];
    
    NSString *message = [ NSString stringWithFormat: @"You left '%@' in zone '%@' after %lu minutes",fence.name, zoneInfo.name, (unsigned long)checkedInDuration ];
    
    [ self showAlert: message ];
}

//MARK: A beacon with a Custom Action has been checked into; display an alert to notify the user.
//beacon         - Beacon triggered
//zoneInfo       - Zone information Beacon belongs to
//location       - Geographical coordinate where trigger happened
//proximity      - Proximity at which the trigger occurred
//customData     - Custom data associated with this Custom Action

- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon
                    inZone: (BDZoneInfo *)zoneInfo
                atLocation: (BDLocationInfo *)location
             withProximity: (CLProximity)proximity
              willCheckOut: (BOOL)willCheckOut
            withCustomData: (NSDictionary *)customData
{
    NSString *proximityString;
    
    switch(proximity)
    {
        default:
        case CLProximityUnknown:   proximityString = @"Unknown";   break;
        case CLProximityImmediate: proximityString = @"Immediate"; break;
        case CLProximityNear:      proximityString = @"Near";      break;
        case CLProximityFar:       proximityString = @"Far";       break;
    }
    
    PIOBeaconRegion *beaconRegion = [[PIOBeaconRegion alloc] initWithiBeaconUUID:beacon.proximityUuid iBeaconMajor:beacon.major iBeaconMinor:beacon.minor beaconId:beacon.ID beaconName:beacon.name beaconTag:@"" proximity:proximityString source:@"BDPointSDK" zoneId:zoneInfo.ID zoneName:zoneInfo.name dwellTime:0 extra:  customData];
    [[PushIOManager sharedInstance] didEnterBeaconRegion:beaconRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            //Beacon Entry Event triggered successfully
        } else {
            NSLog(@"Unable to send Beacon Entry Event, reason: %@", error.description);
        }
    }];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    
    NSString *message = [ NSString stringWithFormat: @"You have checked into beacon '%@' in zone '%@' with proximity %@ at %@",beacon.name,zoneInfo.name,proximityString,[ _dateFormatter stringFromDate: location.timestamp ] ];
    
    [ self showAlert: message ];
    
}

//MARK: A beacon with a Custom Action has been checked out from; display an alert to notify the user.
//beacon               - Beacon triggered
//zoneInfo             - Zone information Beacon belongs to
//checkedInDuration    - Time spent inside the Fence; in minutes
//customData           - Custom data associated with this Custom Action
//proximity            - Proximity at which the trigger occurred

- (void)didCheckOutFromBeacon: (BDBeaconInfo *)beacon
                       inZone: (BDZoneInfo *)zoneInfo
                withProximity: (CLProximity)proximity
                       onDate: (NSDate *)date
                 withDuration: (NSUInteger)checkedInDuration
               withCustomData: (NSDictionary *)customData
{
    NSString *proximityString;
    
    switch(proximity)
    {
        default:
        case CLProximityUnknown:   proximityString = @"Unknown";   break;
        case CLProximityImmediate: proximityString = @"Immediate"; break;
        case CLProximityNear:      proximityString = @"Near";      break;
        case CLProximityFar:       proximityString = @"Far";       break;
    }
    
    PIOBeaconRegion *beaconRegion = [[PIOBeaconRegion alloc] initWithiBeaconUUID:beacon.proximityUuid iBeaconMajor:beacon.major iBeaconMinor:beacon.minor beaconId:beacon.ID beaconName:beacon.name beaconTag:@"" proximity:proximityString source:@"BDPointSDK" zoneId:zoneInfo.ID zoneName:zoneInfo.name dwellTime:checkedInDuration extra:  customData];
   
    [[PushIOManager sharedInstance] didExitBeaconRegion:beaconRegion completionHandler:^(NSError *error, NSString *response) {
        if (nil == error) {
            //Beacon Exit Event triggered successfully
        } else {
            NSLog(@"Unable to send Beacon Exit Event, reason: %@", error.description);
        }
    }];
    
    NSString *message = [ NSString stringWithFormat: @"You left beacon '%@' in zone '%@', after %lu minutes",
                         beacon.name, zoneInfo.name, (unsigned long)checkedInDuration ];
    
    [ self showAlert: message ];
}

//MARK: This method is part of the Bluedot location delegate and is called when Bluetooth is required by the SDK but is not enabled on the device; requiring user intervention.
- (void)didStartRequiringUserInterventionForBluetooth
{
    if ( _userInterventionForBluetoothDialog == nil )
    {
        NSString  *title = @"Bluetooth Required";
        NSString  *message = @"There are nearby Beacons which cannot be detected because Bluetooth is disabled.  Re-enable Bluetooth to restore full functionality.";
        
        _userInterventionForBluetoothDialog = [ UIAlertController alertControllerWithTitle:
                                               title message: message
                                                                            preferredStyle: UIAlertControllerStyleAlert ];
        
        UIAlertAction *dismiss = [ UIAlertAction actionWithTitle: @"Dismiss" style: UIAlertActionStyleCancel handler: nil ];
        [ _userInterventionForBluetoothDialog addAction: dismiss ];
    }
    
    [self.window.rootViewController presentViewController: _userInterventionForBluetoothDialog animated: YES completion: nil ];
}


//MARK: This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously been required to enable Bluetooth and either user intervention has enabled Bluetooth or the Bluetooth service is no longer required.

- (void)didStopRequiringUserInterventionForBluetooth
{
    [ _userInterventionForBluetoothDialog dismissViewControllerAnimated: YES completion: nil ];
}

//MARK:  This method is part of the Bluedot location delegate and is called when Location Services are not enabled on the device; requiring user intervention.

- (void)didStartRequiringUserInterventionForLocationServicesAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    if(authorizationStatus == kCLAuthorizationStatusDenied)
    {
        if ( _userInterventionForLocationServicesNeverDialog == nil )
        {
            NSString  *appName = [ NSBundle.mainBundle objectForInfoDictionaryKey: @"CFBundleDisplayName" ];
            NSString  *title = @"Location Services Required";
            NSString  *message = [ NSString stringWithFormat: @"This App requires Location Services which are currently set to disabled.  To restore Location Services, go to :\nSettings → Privacy →\nLocation Settings →\n%@ ✓", appName ];
            
            _userInterventionForLocationServicesNeverDialog = [ UIAlertController
                                                               alertControllerWithTitle: title
                                                               message: message
                                                               preferredStyle: UIAlertControllerStyleAlert ];
            
        }
        
        UIViewController *currentPresentedViewController = self.window.rootViewController.presentedViewController;
        if([currentPresentedViewController isKindOfClass:[UIAlertController class]])
        {
            __weak typeof(self) weakSelf = self;
            
            [currentPresentedViewController dismissViewControllerAnimated:YES completion:^(void){
                
                if (weakSelf != nil) {
                    [weakSelf.window.rootViewController presentViewController: self->_userInterventionForLocationServicesNeverDialog animated: YES completion: nil];
                }
                
            }];
        }
        else
        {
            [self.window.rootViewController presentViewController: _userInterventionForLocationServicesNeverDialog animated: YES completion: nil];
        }
    }
    else if(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        if (_userInterventionForLocationServicesWhileInUseDialog == nil) {
            NSString *title = @"Location Services set to 'While in Use'";
            NSString *message = [NSString stringWithFormat:@"You can ask for further location permission from user via this delegate method"];
            
            _userInterventionForLocationServicesWhileInUseDialog = [UIAlertController
                                                                    alertControllerWithTitle:title
                                                                    message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
            [_userInterventionForLocationServicesWhileInUseDialog addAction:dismiss];
        }
        
        UIViewController *currentPresentedViewController = self.window.rootViewController.presentedViewController;
        if([currentPresentedViewController isKindOfClass:[UIAlertController class]])
        {
            __weak typeof(self) weakSelf = self;
            
            [currentPresentedViewController dismissViewControllerAnimated:YES completion:^(void){
                
                if (weakSelf != nil) {
                    [weakSelf.window.rootViewController presentViewController: self->_userInterventionForLocationServicesWhileInUseDialog animated: YES completion: nil];
                }
                
            }];
        }
        else
        {
            [self.window.rootViewController presentViewController: _userInterventionForLocationServicesWhileInUseDialog animated: YES completion: nil];
        }
    }
    
}

//MARK: This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously been required to enable Location Services and either Location Services has been enabled or the user is no longer within anauthenticated session, thereby no longer requiring Location Services.

- (void)didStopRequiringUserInterventionForLocationServicesAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    UIViewController *currentPresentedViewController = self.window.rootViewController.presentedViewController;
    if([currentPresentedViewController isKindOfClass:[UIAlertController class]])
    {
        [currentPresentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

//MARK: This method is part of the Bluedot location delegate and is called when Low Power mode is enabled on the device; requiring user intervention to restore full SDK precision.

- (void)didStartRequiringUserInterventionForPowerMode
{
    if ( _userInterventionForPowerModeDialog == nil )
    {
        NSString  *title = @"Low Power Mode";
        NSString  *message = [ NSString stringWithFormat: @"Low Power Mode has been enabled on this device.  To restore full location precision, disable the setting at :\nSettings → Battery → Low Power Mode" ];
        
        _userInterventionForPowerModeDialog = [ UIAlertController alertControllerWithTitle: title
                                                                                   message: message
                                                                            preferredStyle: UIAlertControllerStyleAlert ];
    }
    
    [self.window.rootViewController presentViewController: _userInterventionForPowerModeDialog animated: YES completion: nil];
}


//MARK: if the user switches off 'Low Power mode', then didStopRequiringUserInterventionForPowerMode is called.
- (void)didStopRequiringUserInterventionForPowerMode
{
    [ _userInterventionForPowerModeDialog dismissViewControllerAnimated: YES completion: nil ];
}

//MARK:-  Post a notifiction message.

- (void)showAlert: (NSString *)message
{
    UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
    
    switch( applicationState )
    {
            // In the foreground: display notification directly to the user
        case UIApplicationStateActive:
        {
            UIAlertController *alertController = [ UIAlertController alertControllerWithTitle:
                                                  @"Application notification"
                                                                                      message: message
                                                                               preferredStyle: UIAlertControllerStyleAlert ];
            
            UIAlertAction *OK = [ UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleCancel handler: nil ];
            
            [ alertController addAction:OK ];
            
            [self.window.rootViewController presentViewController: alertController animated: YES completion: nil];
        }
            break;
            
            // If not in the foreground: deliver a local notification
        default:
        {
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
        }
            break;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:
(NSData *)deviceToken
{
    [[PushIOManager sharedInstance]  didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[PushIOManager sharedInstance]  didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[PushIOManager sharedInstance] didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:
(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[PushIOManager sharedInstance] didReceiveRemoteNotification:userInfo
                                           fetchCompletionResult:UIBackgroundFetchResultNewData fetchCompletionHandler:completionHandler];
}

//iOS 10
-(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:
(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler
{
    [[PushIOManager sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response
                                     withCompletionHandler:completionHandler];
}

-(void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:
(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    [[PushIOManager sharedInstance] userNotificationCenter:center willPresentNotification:notification
                                     withCompletionHandler:completionHandler];
}

@end
