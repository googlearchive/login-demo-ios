#!/bin/bash
set -o nounset
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SDK_DIR="$SCRIPT_DIR/sdk"

FIREBASE_SDK_URL="https://cdn.firebase.com/ObjC/Firebase.framework-LATEST.zip"
FIREBASE_SDK_ZIP_FILE="firebase-sdk.zip"
FIREBASE_SDK_DIR="$SCRIPT_DIR/sdk/Firebase.framework"

SIMPLE_LOGIN_SDK_URL="https://cdn.firebase.com/ios/FirebaseSimpleLogin.framework-LATEST.zip"
SIMPLE_LOGIN_SDK_ZIP_FILE="simple-login-sdk.zip"
SIMPLE_LOGIN_SDK_DIR="$SCRIPT_DIR/sdk/FirebaseSimpleLogin.framework"

GOOGLE_SDK_URL="https://developers.google.com/+/mobile/ios/sdk/google-plus-ios-sdk-1.7.0.zip"
GOOGLE_SDK_ZIP_FILE="google-plus-sdk.zip"

FACEBOOK_SDK_URL="https://developers.facebook.com/resources/facebook-ios-sdk-3.18.2.pkg"
FACEBOOK_SDK_PKG_FILE="facebook-sdk.pkg"

download_sdk() {
    FRAMEWORK_NAME="$1"
    SDK_URL="$2"
    SDK_FILE="$3"
    if [ -f "$SDK_DIR/$SDK_FILE" ]; then
        echo "$FRAMEWORK_NAME file already present. Skipping download..." 1>&2
    else
        echo "Downloading $FRAMEWORK_NAME ..." 1>&2
        curl -L "$SDK_URL" -o "$SDK_DIR/$SDK_FILE"
    fi

    if [[ $SDK_FILE =~ \.zip$ ]]; then
        echo "Extracting $FRAMEWORK_NAME ..." 1>&2
        unzip -o -qq "$SDK_DIR/$SDK_FILE" -d "$SDK_DIR"
    elif [[ $SDK_FILE =~ \.pkg$ ]]; then
        echo "Launching $FRAMEWORK_NAME installer..." 1>&2
        open -W "$SDK_DIR/$SDK_FILE"
    else
        echo "Unknown SDK Type: $SDK_FILE" 1>&2
    fi
}

echo "$SDK_DIR"

mkdir -p "$SDK_DIR"

download_sdk "Firebase SDK" "$FIREBASE_SDK_URL" "$FIREBASE_SDK_ZIP_FILE"
download_sdk "Firebase Simple Login SDK" "$SIMPLE_LOGIN_SDK_URL" "$SIMPLE_LOGIN_SDK_ZIP_FILE"
download_sdk "Google+ SDK" "$GOOGLE_SDK_URL" "$GOOGLE_SDK_ZIP_FILE"

download_sdk "Facebook SDK" "$FACEBOOK_SDK_URL" "$FACEBOOK_SDK_PKG_FILE"
cp -r ~/Documents/FacebookSDK/FacebookSDK.framework "$SDK_DIR/FacebookSDK.framework"

echo "All done..." 1>&2
