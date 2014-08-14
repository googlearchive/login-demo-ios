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

download_sdk() {
    FRAMEWORK_NAME="$1"
    SDK_URL="$2"
    SDK_ZIP_FILE="$3"
    if [ -f "$SDK_DIR/$SDK_ZIP_FILE" ]; then
        echo "$FRAMEWORK_NAME zip file already present. Skipping download..." 1>&2
    else
        echo "Downloading $FRAMEWORK_NAME ..." 1>&2
        curl -L "$SDK_URL" -o "$SDK_DIR/$SDK_ZIP_FILE"
    fi
    echo "Extracting $FRAMEWORK_NAME ..." 1>&2
    unzip -o -qq "$SDK_DIR/$SDK_ZIP_FILE" -d "$SDK_DIR"
}


echo "$SDK_DIR"

mkdir -p "$SDK_DIR"

download_sdk "Firebase SDK" "$FIREBASE_SDK_URL" "$FIREBASE_SDK_ZIP_FILE"
download_sdk "Firebase Simple Login SDK" "$SIMPLE_LOGIN_SDK_URL" "$SIMPLE_LOGIN_SDK_ZIP_FILE"
download_sdk "Google+ SDK" "$GOOGLE_SDK_URL" "$GOOGLE_SDK_ZIP_FILE"

#if [ -f "$FIREBASE_SDK_ZIP_FILE" ]; then
#    echo "Firebase zip already present. Skipping download..." 1>&2
#else
#    echo "Downloading Firebase SDK..." 1>&2
#    curl "$FIREBASE_SDK_URL" -o "$FIREBASE_SDK_ZIP_FILE"
#fi
#
#
#if [ -d "$FIREBASE_SDK_DIR" ]; then
#    echo "Firebase SDK already installed" 1>&2
#else
#    echo "Extracting Firebase SDK..." 1>&2
#    unzip "$FIREBASE_SDK_ZIP_FILE" -d "$SDK_DIR"
#fi
#
#if [ -f "$SIMPLE_LOGIN_SDK_ZIP_FILE" ]; then
#    echo "Firebase Simple Login zip already present. Skipping download..." 1>&2
#else
#    echo "Downloading Firebase Simple Login SDK..." 1>&2
#    curl "$SIMPLE_LOGIN_SDK_URL " -o "$SIMPLE_LOGIN_SDK_ZIP_FILE"
#fi
#
#
#if [ -d "$SIMPLE_LOGIN_SDK_DIR" ]; then
#    echo "Firebase Simple Login SDK already installed" 1>&2
#else
#    echo "Extracting Firebase Simple Login SDK..." 1>&2
#    unzip "$SIMPLE_LOGIN_SDK_ZIP_FILE" -d "$SDK_DIR"
#fi

echo "All done..." 1>&2
