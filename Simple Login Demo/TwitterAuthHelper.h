//
//  TwitterAuthHelper.h
//  Simple Login Demo
//
//  Created by Katherine Fang on 9/30/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#ifndef Simple_Login_Demo_TwitterAuthHelper_h
#define Simple_Login_Demo_TwitterAuthHelper_h

#import <Firebase/Firebase.h>

@interface TwitterAuthHelper : NSObject

@property (strong, nonatomic) ACAccountStore *store;
@property (strong, nonatomic) Firebase *ref;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSArray *accounts;

- (id) initWithFirebaseRef:(Firebase *)ref apiKey:(NSString *)apiKey;

// Step 1a
- (void) selectTwitterAccountWithCallback:(void (^)(NSError *error, NSArray *accounts))callback;

// Step 1b through 3:
- (void) authenticateAccount:(ACAccount *)account withCallback:(void (^)(NSError *error, FAuthData *authData))callback;

@end

typedef NS_ENUM(NSInteger, AuthHelperError) {
    AuthHelperErrorAccountAccessDenied = -1,
    AuthHelperErrorOAuthTokenRequestDenied = -2
};

#endif
