# musicapp

flutter run
flutter doctor
flutter build apk
flutter devices
flutter install apk
flutter emulators
flutter emulators --launch Pixel_8_Pro_API_34
flutter clean; flutter build apk --release; flutter install apk --release

flutter pub outdated # check dependencies
flutter pub upgrade # upgrade dependencies

### Update without replacing:

(Optional: Increase versionname and versioncode in android/local.properties)

```
flutter build apk --release; adb install -r build\app\outputs\flutter-apk\app-release.apk
```

