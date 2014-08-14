//
//  SLViewController.m
//  Simple Login Demo
//
//  Created by Jonny Dimond on 8/11/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#import "SLViewController.h"

#import <Accounts/Accounts.h>
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import <GoogleOpenSource/GoogleOpenSource.h>

// The Firebase you want to use for this app
// You must setup Simple Login for the various authentication providers in Forge
static NSString * const kFirebaseURL = @"https://<your-firebase>.firebaseio.com";

// The app ID you setup in the facebook developer console
static NSString * const kFacebookAppID = @"<your-facebook-app-id>";

// The twitter API key you setup in the Twitter developer console
static NSString * const kTwitterAPIKey = @"<your-twitter-app-api-key>";

// The Google client ID you setup in the Google developer console
static NSString * const kGoogleClientID = @"<your-google-client-id>";

@interface SLViewController ()

// The login buttons and status labels
@property (nonatomic, strong) IBOutlet UIButton *facebookLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *twitterLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *googleLoginButton;
@property (strong, nonatomic) IBOutlet UIButton *anonymousLoginButton;
@property (nonatomic, strong) IBOutlet UILabel *loginStatusLabel;
@property (nonatomic, strong) IBOutlet UIButton *logoutButton;

// A dialog that is displayed while logging in
@property (nonatomic, strong) UIAlertView *loginProgressAlert;

// The simpleLogin object that is used to authenticate against Firebase
@property (nonatomic, strong) FirebaseSimpleLogin *simpleLogin;

// The user currently authenticed with Firebase
@property (nonatomic, strong) FAUser *currentUser;

@end

@implementation SLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // setup views
    self.loginStatusLabel.hidden = YES;
    self.loginStatusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.loginStatusLabel.numberOfLines = 0;
    self.logoutButton.hidden = YES;
    // map buttons to methods
    [self.facebookLoginButton addTarget:self
                                 action:@selector(facebookButtonPressed)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.twitterLoginButton addTarget:self
                                action:@selector(twitterButtonPressed)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.googleLoginButton addTarget:self
                               action:@selector(googleButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.anonymousLoginButton addTarget:self
                                  action:@selector(anonymousButtonPressed)
                        forControlEvents:UIControlEventTouchUpInside];
    [self.logoutButton addTarget:self
                          action:@selector(logout)
                forControlEvents:UIControlEventTouchUpInside];

    // create the simple login instance
    Firebase *firebase = [[Firebase alloc] initWithUrl:kFirebaseURL];
    self.simpleLogin = [[FirebaseSimpleLogin alloc] initWithRef:firebase];
}


// sets the user and updates the UI
- (void)updateUIAndSetCurrentUser:(FAUser *)currentUser
{
    // set the user
    self.currentUser = currentUser;
    if (currentUser == nil) {
        // The is no user authenticated, so show the login buttons and hide the logout button
        self.loginStatusLabel.hidden = YES;
        self.logoutButton.hidden = YES;
        self.facebookLoginButton.hidden = NO;
        self.googleLoginButton.hidden = NO;
        self.twitterLoginButton.hidden = NO;
        self.anonymousLoginButton.hidden = NO;
    } else {
        // update the status label to show which user is logged in using which provider
        NSString *statusText;
        switch (currentUser.provider) {
            case FAProviderFacebook:
                statusText = [NSString stringWithFormat:@"Logged in as %@ (Facebook)",
                              currentUser.thirdPartyUserData[@"name"]];
                break;
            case FAProviderTwitter:
                statusText = [NSString stringWithFormat:@"Logged in as %@ (Twitter)",
                              currentUser.thirdPartyUserData[@"name"]];
                break;
            case FAProviderGoogle:
                statusText = [NSString stringWithFormat:@"Logged in as %@ (Google+)",
                              currentUser.thirdPartyUserData[@"name"]];
                break;
            case FAProviderAnonymous:
                statusText = @"Logged in anonymously";
                break;
            default:
                statusText = [NSString stringWithFormat:@"Logged in with unknown provider"];
                break;
        }
        self.loginStatusLabel.text = statusText;
        self.loginStatusLabel.hidden = NO;
        // show the logout button
        self.logoutButton.hidden = NO;
        // hide the login button for now
        self.facebookLoginButton.hidden = YES;
        self.googleLoginButton.hidden = YES;
        self.twitterLoginButton.hidden = YES;
        self.anonymousLoginButton.hidden = YES;
    }
}

- (void)logoutButtonPressed
{
    // logout of Firebase and set the current user to nil
    [self.simpleLogin logout];
    [self updateUIAndSetCurrentUser:nil];
}

- (void)showProgressAlert
{
    // show an alert notifying the user about logging in
    self.loginProgressAlert = [[UIAlertView alloc] initWithTitle:nil
                                                         message:@"Logging in..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [self.loginProgressAlert show];
}

- (void)showErrorAlertWithMessage:(NSString *)message
{
    // display an alert with the error message
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void(^)(NSError *, FAUser *))loginBlockForProviderName:(NSString *)providerName
{
    // this callback block can be used for every login method
    return ^(NSError *error, FAUser *user) {
        // make sure we are on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            // hide the login progress dialog
            [self.loginProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            self.loginProgressAlert = nil;
            if (error != nil) {
                // there was an error authenticating with Firebase
                NSLog(@"Error logging in to Firebase: %@", error);
                // display an alert showing the error message
                NSString *message = [NSString stringWithFormat:@"There was an error logging into Firebase using %@: %@",
                                     providerName,
                                     [error localizedDescription]];
                [self showErrorAlertWithMessage:message];
            } else {
                // all is fine, set the current user and update UI
                [self updateUIAndSetCurrentUser:user];
            }
        });
    };
}

/*****************************
 *          FACEBOOK         *
 *****************************/
- (void)facebookButtonPressed
{
    [self showProgressAlert];
    // login using Facebook
    [self.simpleLogin loginToFacebookAppWithId:kFacebookAppID
                                   permissions:@[@"email"]
                                      audience:ACFacebookAudienceOnlyMe
                           withCompletionBlock:[self loginBlockForProviderName:@"Facebook"]];
}

/*****************************
 *          GOOGLE+          *
 *****************************/
- (void)googleButtonPressed
{
    [self showProgressAlert];
    // use the Google+ SDK to get an OAuth token
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.clientID = kGoogleClientID;
    signIn.scopes = @[ kGTLAuthScopePlusLogin ];
    signIn.delegate = self;
    // authenticate will do a callback to finishedWithAuth:error:
    [signIn authenticate];
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    NSLog(@"Received Googl+ authentication response! Error: %@", error);
    if (error != nil) {
        // there was an error obtaining the Google+ OAuth token, display a dialog
        [self.loginProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
        NSString *message = [NSString stringWithFormat:@"There was an error logging into Google+: %@",
                             [error localizedDescription]];
        [self showErrorAlertWithMessage:message];
    } else {
        // We successfully obtained an OAuth token, authenticate on Firebase with it
        [self.simpleLogin loginWithGoogleWithAccessToken:auth.accessToken withCompletionBlock:[self loginBlockForProviderName:@"Google+"]];
    }
}

/*****************************
 *          TWITTER          *
 *****************************/
- (void)twitterButtonPressed
{
    [self showProgressAlert];
    [self.simpleLogin loginToTwitterAppWithId:kTwitterAPIKey
                      multipleAccountsHandler:^int(NSArray *usernames) {
                          // here you could display a dialog letting the user choose
                          // for simplicity we just choose the first
                          return 0;
                      }
                          withCompletionBlock:[self loginBlockForProviderName:@"Twitter"]];
}

/*****************************
 *         ANONYMOUS         *
 *****************************/
- (void)anonymousButtonPressed
{
    [self showProgressAlert];
    [self.simpleLogin loginAnonymouslywithCompletionBlock:[self loginBlockForProviderName:@"Anonymous"]];
}


@end
