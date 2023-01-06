import 'dart:convert';
import 'package:musicapp/database.dart';
import 'package:musicapp/song.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/songdataframe.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:http/http.dart' as http;

void main() async {
  // https://docs.flutter.dev/cookbook/persistence/sqlite

  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database and store the reference.
  var database = await getDbConnection();

  runApp(MyApp(
    key: const Key("main"),
    db: database,
  ));
}

class MyApp extends StatefulWidget {
  final Database db;
  const MyApp({super.key, required this.db});

  @override
  // ignore: no_logic_in_create_state
  State<MyApp> createState() => _MyAppState(db: db);
}

class _MyAppState extends State<MyApp> {
  final Database db;
  _MyAppState({required this.db});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        db: db,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Database db;
  const MyHomePage({super.key, required this.title, required this.db});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  // ignore: no_logic_in_create_state
  State<MyHomePage> createState() => _MyHomePageState(db: db);
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState({required this.db});
  final Database db;
  final AudioPlayer player = AudioPlayer();

  final androidConfig = const FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText:
        "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Max,
    notificationIcon:
        AndroidResource(name: 'background_icon', defType: 'drawable'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SongDataFrame(
              key: const Key("song1"),
              player: player,
              db: db,
            ),
            MaterialButton(
                color: Colors.blueAccent.shade100,
                onPressed: recreateSongDatabase,
                child: const Text("recreate song database")),
            // MaterialButton(
            //     color: Colors.blueAccent.shade100,
            //     onPressed: listSongs,
            //     child: const Text("alles nur geklaut")),
          ],
        ),
      ),
    );
  }

  void recreateSongDatabase() async {
    var response = await http.get(Uri.parse('https://music.stschiff.de/songs'));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      List<dynamic> songsJson = jsonDecode(response.body);
      List<Song> songs = [];
      for (var s in songsJson) {
        songs.add(Song.fromJson(s));
        // print(s);
        await songs.last.saveToDb(db);
      }
      print("done!");
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  void listSongs() async {
    // final List<Map<String, dynamic>> maps = await db.query('songs');
    // var songs = maps.map((e) => {print(e), Song.fromJson(e)});
    // for (var s in songs) {
    //   print(s);
    // }
    // var s = await Song.fetchRandom(widget.db);
    // await s.download();
    // widget.
  }
}
