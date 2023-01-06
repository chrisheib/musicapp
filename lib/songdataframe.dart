import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/number_prompt.dart';
import 'package:musicapp/path.dart';
import 'package:mutex/mutex.dart';
import 'song.dart';

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  // String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inMinutes)}:$twoDigitSeconds";
}

class SongDataFrame extends StatefulWidget {
  final AudioPlayer player;
  const SongDataFrame({required Key key, required this.player})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SongDataFrameState();
}

class _SongDataFrameState extends State<SongDataFrame> {
  late Song song;
  bool playing = false;
  final m = Mutex();

  _SongDataFrameState() {
    song = Song(
        id: 0,
        title: "",
        album: "",
        artist: "",
        length: "",
        filename: "",
        rating: 0,
        downloaded: 0);
    Timer.periodic(const Duration(milliseconds: 150), (Timer t) async {
      // print(
      // "playing: ${playing}, pos: ${widget.player.position}, dur: ${widget.player.duration}");
      await m.protect(() async {
        if (playing &&
            widget.player.position >=
                (widget.player.duration ?? const Duration(days: 1 << 63))) {
          if (playing) {
            await play(protected: false);
          }
        }
      });

      setState(() {});
    });
  }

  Future<void> play({int id = -1, bool protected = true}) async {
    if (protected) {
      await m.acquire();
      print("acquire lock");
    }

    try {
      await widget.player.stop();
      do {
        if (id == -1) {
          var db = await getDbConnection();
          song = await Song.fetchRandom(db);
        } else {
          song = await Song.fetch(id);
        }
        // var songid = song.id;
        if (song.downloaded != 1) {
          await song.download();
        }
        if (song.downloaded != 1) {
          print("Song not downloaded, retry.");
        }
      } while (song.downloaded != 1);
      var path = await getSongDir(song.id.toString());
      print(path);

      await widget.player.setFilePath(path);

      // Load a URL

      // await widget.player.setUrl(// Load a URL
      //     'https://music.stschiff.de/songs/$songid'); // Schemes: (https: | file: | asset: )
      // await widget.player.setLoopMode(LoopMode.all);
      widget.player.play(); // Play without waiting for completion
      playing = true;
    } finally {
      if (protected) {
        m.release();
        print("release lock");
      }
    }
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
          ProgressBar(
            progress: widget.player.position,
            total: widget.player.duration ?? const Duration(days: 0),
            onSeek: (duration) {
              print('User selected a new time: $duration');
              widget.player.seek(duration);
            },
          ),
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
    var db = await getDbConnection();
    String number_string = await promptNumber(context) ?? "0";
    int number = int.parse(
      number_string,
      onError: (source) {
        Fluttertoast.showToast(
            msg: "Du Tröte musst schon eine Nummer eingeben!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red.shade300,
            textColor: Colors.black,
            fontSize: 16.0);
        throw Exception("Number expected, got $number_string");
      },
    );
    final List<Map<String, dynamic>> maps =
        await db.query('songs', orderBy: "rating DESC", limit: number);
    var songs = maps.map((e) {
      return Song.fromJson(e);
    });
    for (Song s in songs) {
      print(s);
      await s.download();
    }
    // var s = await Song.fetchRandom(widget.db);
    // await s.download();
    // stop();
    // await play(4666);
    // getFreeSpace();
  }
}
