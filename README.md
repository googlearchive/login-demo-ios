# Login Demo for iOS

This is a demo of using Firebase's authentication features in
your iOS app. It focuses on using OAuth with Google, Facebook, or Twitter. Note that
Firebase also supports authentication with email & password and custom auth tokens.
You can read the full [iOS authentication guide here](https://www.firebase.com/docs/ios/guide/user-auth.html).

This demo requires that [Cocoapods](https://cocoapods.org/) is installed.

Running the Demo
----------------

To download and setup all necessary SDKs, run:

    pod install

Next, open `Login Demo.xcworkspace` in XCode (not `Login Demo.xcodeproj`,
since you need to include the Cocoapod dependencies).

You'll then need to edit the file `Login Demo/ViewController.m` and specify the
Firebase app you're using as well as your Twitter / Google / Facebook OAuth API key.
Don't forget to [enable the relevant OAuth providers](https://www.firebase.com/docs/ios/guide/user-auth.html#section-enable-providers)
in your Firebase app.

Finally, run the demo app in XCode!
