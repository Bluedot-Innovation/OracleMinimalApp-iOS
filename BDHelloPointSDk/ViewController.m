//
//  ViewController.m
//  BDHelloPointSDk
//
//  Created by Neha  on 23/4/19.
//  Copyright © 2019 Bluedot. All rights reserved.
//

#import "ViewController.h"
@import BDPointSDK;

@interface ViewController ()

@end

@implementation ViewController

NSString  *projectId = @"d8267470-24ea-435e-86ad-08fd39b7fb4d";

- (void)viewDidLoad {
    [super viewDidLoad];
    [BDLocationManager.instance requestWhenInUseAuthorization];
}

- (IBAction)initializeSDKTouchInsideUp:(id)sender {
    if(![BDLocationManager.instance isInitialized]){
        [BDLocationManager.instance initializeWithProjectId:projectId completion:^(NSError * _Nullable error) {
            if(error != nil) {
                NSLog(@"Initialization Error");
            }
            [BDLocationManager.instance requestAlwaysAuthorization];
        }];
    }
}

- (IBAction)startTriggeringTouchInsideUp:(id)sender {
    [BDLocationManager.instance startGeoTriggeringWithCompletion: ^(NSError * _Nullable error) {
        if(error != nil) {
            NSLog(@"Start Geotrigerring Error");
        }
    }];
}

- (IBAction)stopTriggeringTouchInsideUp:(id)sender {
    [BDLocationManager.instance stopGeoTriggeringWithCompletion: ^(NSError * _Nullable error) {
        if(error != nil) {
            NSLog(@"Stop Geotrigerring Error");
        }
    }];
}

@end
