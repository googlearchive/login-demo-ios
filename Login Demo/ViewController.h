//
//  ViewController.h
//  Login Demo
//
//  Created by Katherine Fang on 5/26/15.
//  Copyright (c) 2015 Firebase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Google/SignIn.h>
#import <Accounts/Accounts.h>
#import <Firebase/Firebase.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface ViewController : UIViewController<UIActionSheetDelegate, GIDSignInDelegate, GIDSignInUIDelegate>

@end

