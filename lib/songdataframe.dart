import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/audio_handler.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/number_prompt.dart';
import 'package:musicapp/path.dart';
import 'package:mutex/mutex.dart';
import 'package:text_scroll/text_scroll.dart';
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
  bool loading = false;
  bool paused = false;
  double? ratingScale;
  double volume = 1;
  DateTime lastSongChange = DateTime.now();
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
        // init rating scale. Must be async :/
        ratingScale ??= await getConfigDouble("rating_scale") ?? 2.5;

        // play next song if skipped in notification
        if (getConfig().skip) {
          getConfig().skip = false;
          print("Skipped in notifiaction, playing next one.");
          await play(protected: false);
        }

        // pause if paused in notification
        if (getConfig().pause) {
          getConfig().pause = false;
          print("Paused in Notification, pausing.");
          pause();
        }

        // pause if paused in notification
        if (getConfig().play) {
          getConfig().play = false;
          print("Play in Notification, calling pause again.");
          pause();
        }

        // play next song if current one is over
        if (playing &&
            widget.player.position >=
                (widget.player.duration ?? const Duration(days: 1 << 63))) {
          if (playing) {
            if (DateTime.now().difference(lastSongChange) >
                const Duration(seconds: 1)) {
              print("End of song, playing next one.");
              await play(protected: false);
            }
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
      await widget.player.seek(const Duration());
      await widget.player.stop();
      // await widget.player.setAudioSource(AudioSource.);
      do {
        if (id == -1) {
          var db = await getDbConnection();
          song = await Song.fetchRandom(db, scale: ratingScale);
        } else {
          song = await Song.fetch(id);
        }
        loading = true;
        setState(() {});

        if (song.downloaded != 1) {
          print("Song not downloaded, first try.");
          await song.download();
        }

        if (song.downloaded != 1) {
          print("Song not downloaded, retry.");
        }
      } while (song.downloaded != 1);
      var path = await getSongDir(song.id.toString());
      print("Setting source: $path");

      getConfig().mediaItem = song.toMediaItem();

      await widget.player.setAudioSource(
          AudioSource.uri(
            Uri.file(path),
            tag: song.toMediaItem(),
          ),
          initialPosition: null,
          initialIndex: null,
          preload: true);

      // getConfig().mediaItem = song.toMediaItem();

      widget.player.play(); // Play without waiting for completion

      loading = false;
      playing = true;
      paused = false;
      lastSongChange = DateTime.now();
    } finally {
      if (protected) {
        m.release();
        print("release lock");
      }
    }
  }

  void pause() async {
    if (!playing) {
      return;
    }
    if (paused) {
      widget.player.play();
      paused = false;
    } else {
      await widget.player.pause();
      paused = true;
    }
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
          TextScroll(
            song.title != "" ? song.title : song.filename,
            style: const TextStyle(fontSize: 30),
            pauseBetween: const Duration(milliseconds: 2500),
            intervalSpaces: 15,
          ),
          TextScroll(
            song.album,
            style: const TextStyle(fontSize: 30),
            pauseBetween: const Duration(milliseconds: 2500),
            intervalSpaces: 15,
          ),
          TextScroll(
            song.artist,
            style: const TextStyle(fontSize: 30),
            pauseBetween: const Duration(milliseconds: 2500),
            intervalSpaces: 15,
          ),
          Text(
              loading
                  ? "00:00 / --:--"
                  : "${printDuration(widget.player.position)} / ${printDuration(widget.player.duration ?? const Duration())}",
              style: const TextStyle(fontSize: 30)),
          Container(
              margin: const EdgeInsets.all(5.0),
              child: ProgressBar(
                progress: widget.player.position,
                total: loading
                    ? const Duration()
                    : widget.player.duration ?? const Duration(),
                onSeek: (duration) {
                  print('User selected a new time: $duration');
                  widget.player.seek(duration);
                },
              )),
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
                    child: Text(getPlayButtonText(),
                        style: const TextStyle(fontSize: 40)),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 175,
                    minWidth: 150,
                    onPressed: playing ? pause : null,
                    color: Colors.blueAccent.shade100,
                    child: Text(paused ? "▶️" : "⏸︎",
                        style: const TextStyle(fontSize: 40)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Scale: ${(ratingScale ?? 3).toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 25)),
              Slider(
                value: ratingScale ?? 3,
                min: 0.5,
                max: 4,
                divisions: 35,
                label: (ratingScale ?? 3).toStringAsFixed(1),
                onChanged: (double value) {
                  setState(() {
                    ratingScale = value;
                    setConfigDouble("rating_scale", value);
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Volume: ${(volume).toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 25)),
              Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 100,
                label: (volume).toStringAsFixed(2),
                onChanged: (double value) {
                  setState(() {
                    volume = value;
                    widget.player.setVolume(volume * volume);
                  });
                },
              ),
            ],
          ),
          MaterialButton(
            color: Colors.blueAccent.shade100,
            onPressed: downloadNSongs,
            child: const Text("Download N songs"),
          ),
        ],
      ),
    );
  }

  void downloadNSongs() async {
    var db = await getDbConnection();
    String numberString = await promptNumber(context) ?? "0";
    int number = int.parse(
      numberString,
      onError: (source) {
        Fluttertoast.showToast(
            msg: "Du Tröte musst schon eine Nummer eingeben!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red.shade300,
            textColor: Colors.black,
            fontSize: 16.0);
        throw Exception("Number expected, got $numberString");
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
  }

  String getPlayButtonText() {
    if (loading) {
      // return '◌';
      return '⏰';
    } else if (playing) {
      return '⏭️';
    } else {
      return "▶️";
    }
  }
}
