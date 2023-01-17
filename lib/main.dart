import 'dart:async';
import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/song.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/songdataframe.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'audio_handler.dart';

void main() async {
  // https://docs.flutter.dev/cookbook/persistence/sqlite

  // Avoid errors caused by flutter upgrade.
  WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerSingleton<SingletonConfig>(SingletonConfig());

  // Open the database once to initialize upgrades
  await getDbConnection();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  await initAudioServiceHandler();

  initRecreateSongDatabaseTimer();

  runApp(const MyApp(
    key: Key("main"),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  _MyAppState();
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
      home: const MyHomePage(
        title: 'Flutter Demo Home Page',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();
  final AudioPlayer player = GetIt.I<AudioPlayer>();

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
            ),
            MaterialButton(
                color: Colors.blueAccent.shade100,
                onPressed: recreateSongDatabase,
                child: const Text("recreate song database")),
          ],
        ),
      ),
    );
  }
}

void initRecreateSongDatabaseTimer() async {
  recreateSongDatabase();
  Timer.periodic(const Duration(minutes: 30), (Timer t) async {
    recreateSongDatabase();
  });
}

void recreateSongDatabase() async {
  var timestamp_str = await getConfigStr("db_recreate_timestamp") ?? "";
  var timestamp = DateTime.tryParse(timestamp_str);
  if (timestamp != null) {
    if (DateTime.now().difference(timestamp) < const Duration(days: 1)) {
      print(
          "Letzter Abgleich ist noch nicht lang genug her. Letzter Abgleich: $timestamp");
      return;
    }
  }
  Fluttertoast.showToast(
      msg: "Beginne Datenbankaktualisierung!",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green.shade300,
      textColor: Colors.black,
      fontSize: 16.0);

  print("Start recreateSongDatabase");
  var response = await http.get(Uri.parse('https://music.stschiff.de/songs'));
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    List<dynamic> songsJson = jsonDecode(response.body);
    var db = await getDbConnection();
    var batch = db.batch();
    batch.execute("delete from songs");
    for (var s in songsJson) {
      var song = Song.fromJson(s);
      // print(song.id);
      song.downloaded = await song.isDownloaded() ? 1 : 0;
      song.saveToDbBatch(batch);
    }
    await batch.commit();
    print("done!");

    Fluttertoast.showToast(
        msg: "Datenbank aktualisiert!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green.shade300,
        textColor: Colors.black,
        fontSize: 16.0);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
  setConfigStr("db_recreate_timestamp", DateTime.now().toString());
  print("End recreateSongDatabase");
}
