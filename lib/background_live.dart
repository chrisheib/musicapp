// import 'package:flutter_background/flutter_background.dart';

// Future<bool> initKeepAlive() async {
//   const androidConfig = FlutterBackgroundAndroidConfig(
//     notificationTitle: "flutter_background example app",
//     notificationText:
//         "Background notification for keeping the example app running in the background",
//     notificationImportance: AndroidNotificationImportance.Default,
//     notificationIcon: AndroidResource(
//         name: 'background_icon',
//         defType: 'drawable'), // Default is ic_launcher from folder mipmap
//   );
//   bool success =
//       await FlutterBackground.initialize(androidConfig: androidConfig);
//   return success;
// }

import 'package:just_audio_background/just_audio_background.dart';

void initKeepAlive() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
}
