import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/path.dart';
import 'package:sqflite/sqflite.dart';

import 'song.dart';

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  // String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inMinutes)}:$twoDigitSeconds";
}

class SongDataFrame extends StatefulWidget {
  final Database db;
  final AudioPlayer player;
  const SongDataFrame(
      {required Key key, required this.player, required this.db})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SongDataFrameState();
}

class _SongDataFrameState extends State<SongDataFrame> {
  late Song song;
  bool playing = false;

  _SongDataFrameState() {
    song = Song(
        id: 0,
        title: "",
        album: "",
        artist: "",
        length: "",
        filename: "",
        rating: 0,
        downloaded: false);
    Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      // print(
      // "playing: ${playing}, pos: ${widget.player.position}, dur: ${widget.player.duration}");
      if (playing &&
          widget.player.position >=
              (widget.player.duration ?? const Duration(days: 1 << 63))) {
        if (playing) {
          await play();
        }
      }
      setState(() {});
    });
  }

  Future<void> play([int id = -1]) async {
    await widget.player.stop();
    if (id == -1) {
      song = await Song.fetchRandom(widget.db);
    } else {
      song = await Song.fetch(id);
    }
    // var songid = song.id;
    if (!song.downloaded) {
      await song.download();
    }
    var path = await getSongDir(song.id.toString());
    print(path);
    await widget.player.setFilePath(path);

    // Load a URL

    // await widget.player.setUrl(// Load a URL
    //     'https://music.stschiff.de/songs/$songid'); // Schemes: (https: | file: | asset: )
    // await widget.player.setLoopMode(LoopMode.all);
    widget.player.play(); // Play without waiting for completion
    playing = true;
  }

  void stop() async {
    playing = false;
    await widget.player.stop();
  }

  void downvoteskip() async {
    if (await song.downvote()) {
      Fluttertoast.showToast(
          msg: "Song downgevotet ⬇️",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.black,
          fontSize: 16.0);
    }
    await play();
  }

  void upvote() async {
    if (!song.upvoted) {
      var success = await song.upvote();
      if (success) {
        Fluttertoast.showToast(
            msg: "Song upgevotet ❤️",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.black,
            fontSize: 16.0);
      }
    } else {
      var success = await song.downvote();
      if (success) {
        Fluttertoast.showToast(
            msg: "Upvote entfernt 💔",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.black,
            fontSize: 16.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(song.title != "" ? song.title : song.filename,
              style: const TextStyle(fontSize: 30)),
          Text(song.artist, style: const TextStyle(fontSize: 30)),
          Text(song.album, style: const TextStyle(fontSize: 30)),
          Text(
              "${printDuration(widget.player.position)} / ${printDuration(widget.player.duration ?? const Duration())}",
              style: const TextStyle(fontSize: 30)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 175,
                    minWidth: 150,
                    onPressed: play,
                    color: Colors.blueAccent.shade100,
                    child: Text(widget.player.playing ? "⏭️" : "▶️",
                        style: const TextStyle(fontSize: 40)),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 175,
                    minWidth: 150,
                    onPressed: stop,
                    color: Colors.blueAccent.shade100,
                    child: const Text("⏹️", style: TextStyle(fontSize: 40)),
                  )),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 175,
                    minWidth: 150,
                    onPressed: upvote,
                    color: song.upvoted
                        ? Colors.greenAccent.shade200
                        : Colors.blueAccent.shade100,
                    child: const Text("💓", style: TextStyle(fontSize: 40)),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 175,
                    minWidth: 150,
                    onPressed: downvoteskip,
                    color: Colors.blueAccent.shade100,
                    child: const Text("🤮", style: TextStyle(fontSize: 40)),
                  )),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(song.rating >= 1 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 2 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 3 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 4 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 5 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 6 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
              Text(song.rating >= 7 ? "★" : "☆",
                  style: const TextStyle(fontSize: 40)),
            ],
          ),
          MaterialButton(
              color: Colors.blueAccent.shade100,
              onPressed: listSongs,
              child: const Text("alles nur geklaut")),
        ],
      ),
    );
  }

  void listSongs() async {
    // final List<Map<String, dynamic>> maps = await db.query('songs');
    // var songs = maps.map((e) => {print(e), Song.fromJson(e)});
    // for (var s in songs) {
    //   print(s);
    // }
    // var s = await Song.fetchRandom(widget.db);
    // await s.download();
    stop();
    await play(4666);
  }
}
