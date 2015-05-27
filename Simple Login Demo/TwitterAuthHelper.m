//
//  TwitterAuthHelper.m
//  Login Demo
//
//  Created by Katherine Fang on 9/30/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#import <Social/Social.h>
#import "TwitterAuthHelper.h"

@interface TwitterAuthHelper ()
@property (strong, nonatomic) ACAccount *account;
@property (nonatomic, copy) void (^userCallback)(NSError *, FAuthData *);
@end

@implementation TwitterAuthHelper

@synthesize store;
@synthesize ref;
@synthesize apiKey;
@synthesize account;
@synthesize accounts;
@synthesize userCallback;

- (id) initWithFirebaseRef:(Firebase *)aRef apiKey:(NSString *)anApiKey {
    self = [super init];
    if (self) {
        self.store = [[ACAccountStore alloc] init];
        self.ref = aRef;
        self.apiKey = anApiKey;
    }
    return self;
}

// Step 1a -- get account
- (void) selectTwitterAccountWithCallback:(void (^)(NSError *error, NSArray *accounts))callback {
    ACAccountType *accountType = [self.store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.store requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [self.store accountsWithAccountType:accountType];
            if ([self.accounts count] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(nil, self.accounts);
                });
            } else {
                NSError *error = [[NSError alloc] initWithDomain:@"TwitterAuthHelper"
                                                            code:AuthHelperErrorAccountAccessDenied
                                                        userInfo:@{NSLocalizedDescriptionKey:@"No Twitter accounts detected on phone. Please add one in the settings first."}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(error, nil);
                });
            }
        } else {
            NSError *error = [[NSError alloc] initWithDomain:@"TwitterAuthHelper"
                                                        code:AuthHelperErrorAccountAccessDenied
                                                    userInfo:@{NSLocalizedDescriptionKey:@"Access to twitter accounts denied."}];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(error, nil);
            });
        }
    }];
}

// Last public facing method
- (void) authenticateAccount:(ACAccount *)anAccount withCallback:(void (^)(NSError *error, FAuthData *authData))callback {
    if (!anAccount) {
        NSError *error = [[NSError alloc] initWithDomain:@"TwitterAuthHelper"
                                                    code:AuthHelperErrorAccountAccessDenied
                                                userInfo:@{NSLocalizedDescriptionKey:@"No Twitter account to authenticate."}];
        callback(error, nil);
    } else {
        self.account = anAccount;
        self.userCallback = callback;
        [self makeReverseRequest]; // kick off step 1b
    }
}

- (void) callbackIfExistsWithError:(NSError *)error authData:(FAuthData *)authData {
    if (self.userCallback) {
        self.userCallback(error, authData);
    }
}

// Step 1b -- get request token from Twitter
- (void) makeReverseRequest {
    [self.ref makeReverseOAuthRequestTo:@"twitter" withCompletionBlock:^(NSError *error, NSDictionary *json) {
        if (error) {
            [self callbackIfExistsWithError:error authData:nil];
        } else {
            SLRequest *request = [self createCredentialRequestWithReverseAuthPayload:json];
            [self requestTwitterCredentials:request];
        }
    }];
}

// Step 1b Helper -- creates request to Twitter
- (SLRequest *) createCredentialRequestWithReverseAuthPayload:(NSDictionary *)json {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    
    NSString *requestToken = [json objectForKey:@"oauth"];
    [params setValue:requestToken forKey:@"x_reverse_auth_parameters"];
    [params setValue:self.apiKey forKey:@"x_reverse_auth_target"];
    
    NSURL* url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    SLRequest* req = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
    [req setAccount:self.account];
    
    return req;
}

// Step 2 -- request credentials from Twitter
- (void) requestTwitterCredentials:(SLRequest *)request {
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callbackIfExistsWithError:error authData:nil];
            });
        } else {
            [self authenticateWithTwitterCredentials:responseData];
        }
    }];
}

// Step 3 -- authenticate with Firebase using Twitter credentials
- (void) authenticateWithTwitterCredentials:(NSData *)responseData {
    NSDictionary *params = [self parseTwitterCredentials:responseData];
    if (params[@"error"]) {
        // There was an error handling the parameters, error out.
        NSError *error = [[NSError alloc] initWithDomain:@"TwitterAuthHelper"
                                                    code:AuthHelperErrorOAuthTokenRequestDenied
                                                userInfo:@{NSLocalizedDescriptionKey:@"OAuth token request was denied.",
                                                @"details": params[@"error"]}];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self callbackIfExistsWithError:error authData:nil];
        });
    } else {
        [self.ref authWithOAuthProvider:@"twitter" parameters:params withCompletionBlock:self.userCallback];
    }
}

// Step 3 Helper -- parsers credentials into dictionary
- (NSDictionary *) parseTwitterCredentials:(NSData *)responseData {
    NSString *accountData = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    NSArray* creds = [accountData componentsSeparatedByString:@"&"];
    for (NSString* param in creds) {
        NSArray* parts = [param componentsSeparatedByString:@"="];
        [params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }

    // This is super fragile error handling, but basically check that the token and token secret are there.
    // If not, return the result that Twitter returned.
    if (!params[@"oauth_token_secret"] || !params[@"oauth_token"]) {
        return @{@"error": accountData};
    } else {
        return params;
    }
}

@end
