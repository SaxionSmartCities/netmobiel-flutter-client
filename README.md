# netmobiel-flutter-client
See [Netmobiel Front-end Wrapper](frontend_app) more info.

# Set up Android packaging

Create a keystore for building the APK as follows:
```
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

Update the key.properties file (in ./frontend_app/android/) as follows:
```
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=key
storeFile=<location of the key store file, such as /Users/<user name>/key.jks>
```

From then on every Android build will produce a signed apk.

Also see: https://flutter.dev/docs/deployment/android


# Set up cloud messaging

See:
https://medium.com/flutterpub/enabling-firebase-cloud-messaging-push-notifications-with-flutter-39b08f2ed723

1. Go to https://console.firebase.google.com
2. Create a new project

## Configuring iOS
1. Add an iOS app to the firebase project
	a. Download the Google services property file (GoogleService-Info.plist)
	b. Add the property fie to the XCode project (in Runner/Runner)
2. Go to https://developer.apple.com
3. Create a new key for Apple Push Notifications service (APNs)
4. Add the key to Firebase (copy paste key id and upload the p8 certificate file)
5. Create an app id in Apple developer console (be sure to check 'Push Notifications')
6. Create a provisioning profile in the Apple developer console
7. Save the provisioning profile file locally on your laptop
8. In XCode enable Push Notifications (XCode will ask for a signing certificate if this has not yet been configured)
9. In the Info.plist add an entry for FirebaseAppDelegateProxyEnabled (value NO)

## Configure Android
