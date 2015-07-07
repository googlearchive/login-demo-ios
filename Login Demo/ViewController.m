//
//  ViewController.m
//  Login Demo
//
//  Created by Jonny Dimond on 8/11/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#import "ViewController.h"
#import "TwitterAuthHelper.h"

// The Firebase you want to use for this app
// You must setup Firebase Login for the various authentication providers in the Dashboard under Login & Auth.
static NSString * const kFirebaseURL = @"https://<your-firebase-app>.firebaseio.com";

// The twitter API key you setup in the Twitter developer console
static NSString * const kTwitterAPIKey = @"<your-twitter-api-key>";

// NOTE: You must configure Google by dragging "GoogleService-Info.plist" to "Supporting Files".
// You must also configure a URL Schemes to match to match the REVERSED_CLIENT_ID and Bundle Identifier.
// See https://developers.google.com/identity/sign-in/ios/start-integrating for more details.

// NOTE: You must configure Facebook in "Supporting Files/Info.plist".
// You need to set FacebookAppID, FacebookDisplayName, and configure a URL Scheme to match your App ID.
// See https://developers.facebook.com/docs/ios/getting-started for more details.


@interface ViewController ()

// The login buttons and status labels
@property (nonatomic, strong) IBOutlet UIButton *facebookLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *twitterLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *googleLoginButton;
@property (strong, nonatomic) IBOutlet UIButton *anonymousLoginButton;
@property (nonatomic, strong) IBOutlet UILabel *loginStatusLabel;
@property (nonatomic, strong) IBOutlet UIButton *logoutButton;

// A dialog that is displayed while logging in
@property (nonatomic, strong) UIAlertView *loginProgressAlert;

// The Firebase object. We use this to authenticate.
@property (nonatomic, strong) Firebase *ref;

// Twitter Auth Helper opbject
@property (nonatomic, strong) TwitterAuthHelper *twitterAuthHelper;

// The user currently authenticed with Firebase
@property (nonatomic, strong) FAuthData *currentUser;

@end

@implementation ViewController

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
    
    // make sure we have a Firebase url
    if ([self firebaseIsSetup]) {
        self.ref = [[Firebase alloc] initWithUrl:kFirebaseURL];
    }
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
            statusText = [NSString stringWithFormat:@"Logged in as %@ (Google)",
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
    [self.ref unauth];
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
 *          Checks Setup
 * These methods check that the necessary constants are set up properly.
 *****************************/

- (BOOL)facebookIsSetup
{
    NSString *facebookAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
    NSString *facebookDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookDisplayName"];
    BOOL canOpenFacebook =[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"fb%@://", facebookAppId]]];
    
    if ([@"<YOUR FACEBOOK APP ID>" isEqualToString:facebookAppId] ||
        [@"<YOUR FACEBOOK APP DISPLAY NAME>" isEqualToString:facebookDisplayName] || !canOpenFacebook) {
        [self showErrorAlertWithMessage:@"Please set FacebookAppID, FacebookDisplayName, and\nURL types > Url Schemes in `Supporting Files/Info.plist`"];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)googleIsSetup
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *reversedClientId =[plist objectForKey:@"REVERSED_CLIENT_ID"];
    BOOL clientIdExists = [plist objectForKey:@"CLIENT_ID"] != nil;
    BOOL reversedClientIdExists = reversedClientId != nil;
    BOOL canOpenGoogle =[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://", reversedClientId]]];

    if (!(clientIdExists && reversedClientIdExists && canOpenGoogle)) {
        [self showErrorAlertWithMessage:@"Please add `GoogleService-Info.plist` to `Supporting Files` and\nURL types > Url Schemes in `Supporting Files/Info.plist`"];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)twitterIsSetup
{
    if ([@"<your-twitter-app-id>" isEqualToString:kTwitterAPIKey]) {
        [self showErrorAlertWithMessage:@"Please set kTwitterAPIKey to your Twitter API Key in ViewController.m"];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)firebaseIsSetup
{
    if ([@"https://<your-firebase-app>.firebaseio.com" isEqualToString:kFirebaseURL]) {
        [self showErrorAlertWithMessage:@"Please set kFirebaseURL to your Firebase's URL in ViewController.m"];
        return NO;
    } else {
        return YES;
    }
}

/*****************************
 *          FACEBOOK         *
 *****************************/

- (void)facebookButtonPressed
{
    if ([self facebookIsSetup]) {
        [self facebookLogin];
    }
}

- (void)facebookLogin {
    
    [self showProgressAlert];
    
    // Open a session showing the user the login UI
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    
    [login logInWithReadPermissions:@[@"email"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            NSLog(@"Facebook login failed. Error: %@", error);
        } else if (result.isCancelled) {
            NSLog(@"Facebook login got cancelled.");
        } else if ([FBSDKAccessToken currentAccessToken]) {
            [self.ref authWithOAuthProvider:@"facebook" token:[[FBSDKAccessToken currentAccessToken] tokenString] withCompletionBlock:[self loginBlockForProviderName:@"Facebook"]];
        }
    }];
}

/*****************************
 *          GOOGLE           *
 *****************************/
- (void)googleButtonPressed
{
    if ([self googleIsSetup]) {
        [self googleLogin];
    }
}

- (void)googleLogin
{
    GIDSignIn *googleSignIn = [GIDSignIn sharedInstance];
    googleSignIn.delegate = self;
    googleSignIn.uiDelegate = self;
    [googleSignIn signIn];
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    NSLog(@"Received Google authentication response! Error: %@", error);
    if (error != nil) {
        // There was an error obtaining the Google OAuth token, display a dialog
        NSString *message = [NSString stringWithFormat:@"There was an error logging into Google: %@",
                             [error localizedDescription]];
        [self showErrorAlertWithMessage:message];
    } else {
        // We successfully obtained an OAuth token, authenticate on Firebase with it
        [self.ref authWithOAuthProvider:@"google" token:user.authentication.accessToken withCompletionBlock:[self loginBlockForProviderName:@"Google"]];
    }

}

/*****************************
 *          TWITTER          *
 *****************************/
- (void)twitterButtonPressed
{
    if ([self twitterIsSetup]) {
        [self twitterLogin];
    }
}

- (void)twitterLogin
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
    if ([self firebaseIsSetup]) {
        [self showProgressAlert];
        [self.ref authAnonymouslyWithCompletionBlock:[self loginBlockForProviderName:@"Anonymous"]];
    }
}


@end
