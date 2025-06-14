import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/song.dart';
import 'package:musicapp/songdataframe.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_logger/simple_logger.dart';

// import 'package:sqflite/sqflite.dart';
import 'audio_handler.dart';

// Singleton (factory)
final logger = SimpleLogger();

void main() async {
  // https://docs.flutter.dev/cookbook/persistence/sqlite

  // Avoid errors caused by flutter upgrade.
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.storage.request();

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
      title: 'MusicApp',
      theme: FlexThemeData.light(scheme: FlexScheme.hippieBlue),
      darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.hippieBlue, darkIsTrueBlack: true),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  // final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();

  final AudioPlayer player = GetIt.I<AudioPlayer>();
  bool compact = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SongDataFrame(
                key: const Key("song1"),
                player: player,
                compact: isCompact(context)),
            if (!isCompact(context))
              MaterialButton(
                  color: Colors.blueAccent.shade100,
                  onPressed: recreateSongDatabase,
                  child: const Text("recreate song database"))
          ],
        ),
      );
    }));
  }
}

bool isCompact(BuildContext context) {
  const double compactLayoutBreakpoint = 300.0; // In logical pixels
  return MediaQuery.of(context).size.height < compactLayoutBreakpoint;
}

void initRecreateSongDatabaseTimer() async {
  recreateSongDatabase();
  Timer.periodic(const Duration(minutes: 30), (Timer t) async {
    recreateSongDatabase();
  });
}

void recreateSongDatabase() async {
  var timestampStr = await getConfigStr("db_recreate_timestamp") ?? "";
  var timestamp = DateTime.tryParse(timestampStr);
  if (timestamp != null) {
    if (DateTime.now().difference(timestamp) < const Duration(days: 1)) {
      logger.info(
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

  logger.info("Start recreateSongDatabase");
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
      // logger.info(song.id);
      song.downloaded = await song.isDownloaded() ? 1 : 0;
      song.saveToDbBatch(batch);
    }
    await batch.commit();
    logger.info("done!");

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
  logger.info("End recreateSongDatabase");
}
