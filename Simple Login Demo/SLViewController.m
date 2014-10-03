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

#import "TwitterAuthHelper.h"

// The Firebase you want to use for this app
// You must setup Simple Login for the various authentication providers in Forge
static NSString * const kFirebaseURL = @"https://<your-firebase>.firebaseio.com";

// The twitter API key you setup in the Twitter developer console
static NSString * const kTwitterAPIKey = @"<your-twitter-app-id>";

// The Google client ID you setup in the Google developer console
static NSString * const kGoogleClientID = @"<your-google-client-id>";

// NOTE: You must configure Facebook in "Supporting Files/Simple Login Demo-Info.plist".
// You need to set FacebookAppID, FacebookDisplayName, and configure a URL Scheme to match your App ID.
// See https://developers.facebook.com/docs/ios/getting-started for more details.


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

// The Firebase object
@property (nonatomic, strong) Firebase *ref;

// Twitter Auth Helper opbject
@property (nonatomic, strong) TwitterAuthHelper *twitterAuthHelper;

// The simpleLogin object that is used to authenticate against Firebase
@property (nonatomic, strong) FirebaseSimpleLogin *simpleLogin;

// The user currently authenticed with Firebase
@property (nonatomic, strong) FAuthData *currentUser;

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
                          action:@selector(logoutButtonPressed)
                forControlEvents:UIControlEventTouchUpInside];

    // create the simple login instance
    self.ref = [[Firebase alloc] initWithUrl:kFirebaseURL];
    self.simpleLogin = [[FirebaseSimpleLogin alloc] initWithRef:self.ref];
}


// sets the user and updates the UI
- (void)updateUIAndSetCurrentUser:(FAuthData *)currentUser
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
        if ([currentUser.provider isEqualToString:@"facebook"]) {
            statusText = [NSString stringWithFormat:@"Logged in as %@ (Facebook)",
                          currentUser.providerData[@"displayName"]];
        } else if ([currentUser.provider isEqualToString:@"twitter"]) {
            statusText = [NSString stringWithFormat:@"Logged in as %@ (Twitter)",
                          currentUser.providerData[@"username"]];
        } else if ([currentUser.provider isEqualToString:@"google"]) {
            statusText = [NSString stringWithFormat:@"Logged in as %@ (Google+)",
                          currentUser.providerData[@"displayName"]];
        } else if ([currentUser.provider isEqualToString:@"anonymous"]) {
            statusText = @"Logged in anonymously";
        } else {
            statusText = [NSString stringWithFormat:@"Logged in with unknown provider"];
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

- (void(^)(NSError *, FAuthData *))loginBlockForProviderName:(NSString *)providerName
{
    // this callback block can be used for every login method
    return ^(NSError *error, FAuthData *authData) {
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
            [self updateUIAndSetCurrentUser:authData];
        }
    };
}

/*****************************
 *          FACEBOOK         *
 *****************************/

- (void)facebookButtonPressed
{
    [self showProgressAlert];

    // Open a session showing the user the login UI
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         if (error) {
             NSLog(@"Facebook login failed. Error: %@", error);
         } else if (state == FBSessionStateOpen) {
             NSString *accessToken = session.accessTokenData.accessToken;
             [self.ref authWithOAuthProvider:@"facebook" token:accessToken withCompletionBlock:[self loginBlockForProviderName:@"Facebook"]];
         }
     }];
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
        [self.ref authWithOAuthProvider:@"google" token:auth.accessToken withCompletionBlock:[self loginBlockForProviderName:@"Google+"]];
    }
}

/*****************************
 *          TWITTER          *
 *****************************/
- (void)twitterButtonPressed
{
    self.twitterAuthHelper = [[TwitterAuthHelper alloc] initWithFirebaseRef:self.ref apiKey:kTwitterAPIKey];
    [self.twitterAuthHelper selectTwitterAccountWithCallback:^(NSError *error, NSArray *accounts) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"There was an error logging into Twitter: %@", [error localizedDescription]];
            [self showErrorAlertWithMessage:message];
        } else {
            // here you could display a dialog letting the user choose
            // for simplicity we just choose the first
            [self showProgressAlert];
            [self.twitterAuthHelper authenticateAccount:[accounts firstObject]
                                           withCallback:[self loginBlockForProviderName:@"Twitter"]];
            
            // If you wanted something more complicated, comment the above line out, and use the below line instead.
            // [self twitterHandleAccounts:accounts];
        }
    }];
}

/*****************************
 *      ADV TWITTER STUFF    *
 *****************************/
- (void)twitterHandleAccounts:(NSArray *)accounts
{
    // Handle the case based on how many twitter accounts are registered with the phone.
    switch ([accounts count]) {
        case 0:
            // There is currently no Twitter account on the device.
            break;
        case 1:
            // Single user system, go straight to login
            [self.twitterAuthHelper authenticateAccount:[accounts firstObject]
                                           withCallback:[self loginBlockForProviderName:@"Twitter"]];
            break;
        default:
            // Handle multiple users by showing action sheet
            [self twitterShowAccountsSheet:accounts];
            break;
    }
}

// For this, you'll need to make sure that your ViewController is a UIActionSheetDelegate.
- (void)twitterShowAccountsSheet:(NSArray *)accounts
{
    UIActionSheet *selectUserActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Twitter Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (ACAccount *account in accounts) {
        [selectUserActionSheet addButtonWithTitle:[account username]];
    }
    selectUserActionSheet.cancelButtonIndex = [selectUserActionSheet addButtonWithTitle:@"Cancel"];
    [selectUserActionSheet showInView:self.view];
}

// Delegate to handle Twitter action sheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *currentTwitterHandle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    for (ACAccount *account in self.twitterAuthHelper.accounts) {
        if ([currentTwitterHandle isEqualToString:account.username]) {
            [self.twitterAuthHelper authenticateAccount:account
                                           withCallback:[self loginBlockForProviderName:@"Twitter"]];
        }
    }
}


/*****************************
 *         ANONYMOUS         *
 *****************************/
- (void)anonymousButtonPressed
{
    [self showProgressAlert];
    [self.ref authAnonymouslyWithCompletionBlock:[self loginBlockForProviderName:@"Anonymous"]];
}


@end
