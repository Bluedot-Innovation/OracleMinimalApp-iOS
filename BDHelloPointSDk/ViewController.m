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

//Add API key for the App
NSString  *apiKey = @"BD-API-KEY";


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Determine the authentication state
    switch( BDLocationManager.instance.authenticationState )
    {
        case BDAuthenticationStateNotAuthenticated:
        {
            [BDLocationManager.instance authenticateWithApiKey: apiKey];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

//MARK:- Stop SDK
- (IBAction)stopSDKBtnActn:(id)sender {
    
    //Determine the authentication state
    switch( BDLocationManager.instance.authenticationState )
    {
        case BDAuthenticationStateAuthenticated:
            [BDLocationManager.instance logOut];
            break;
            
        default:
            break;
    }
}

@end
