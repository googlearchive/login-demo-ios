# Status: Archived
This repository has been archived and is no longer maintained.

![status: inactive](https://img.shields.io/badge/status-inactive-red.svg)

# This is a legacy Firebase example (for SDK 2.x.x). You probably want to use one of the up-to-date examples at https://firebase.google.com/docs/samples

---

# Login Demo for iOS

This is a demo of using Firebase's authentication features in
your iOS app. It focuses on using OAuth with Google, Facebook, or Twitter,
as well as anonymous authentication. Note that
Firebase also supports authentication with email & password and custom auth tokens.
You can read the full [iOS authentication guide here](https://www.firebase.com/docs/ios/guide/user-auth.html).

This demo requires that [CocoaPods](https://cocoapods.org/) is installed.

Running the Demo
----------------

To download and setup all necessary SDKs, run:

    pod install

Next, open `Login Demo.xcworkspace` in XCode (not `Login Demo.xcodeproj`,
since you need to include the Cocoapod dependencies).

You'll then need to edit the file `Login Demo/ViewController.m` and specify the
Firebase app you're using as well as your Twitter API key. To setup
Facebook auth, you'll need to open `Supporting Files/Info.plist`.
and set FacebookAppID and FacebookDisplayName as well as configure a
URL Scheme to match your App ID. To setup
Google auth, you'll need to create and add a `GoogleService-Info.plist` from [here](https://developers.google.com/mobile/add?platform=ios&cntapi=signin&cnturl=https:%2F%2Fdevelopers.google.com%2Fidentity%2Fsign-in%2Fios%2Fsign-in%3Fconfigured%3Dtrue&cntlbl=Continue%20Adding%20Sign-In) as well as configure a
URL Scheme to match your Reversed Client ID.

Don't forget to [enable the relevant OAuth providers](https://www.firebase.com/docs/ios/guide/user-auth.html#section-enable-providers)
in your Firebase app.

Finally, run the demo app in XCode!
