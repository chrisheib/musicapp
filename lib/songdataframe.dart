import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'song.dart';

class SongDataFrame extends StatefulWidget {
  final AudioPlayer player;
  const SongDataFrame({required Key key, required this.player})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SongDataFrameState();
}

class _SongDataFrameState extends State<SongDataFrame> {
  late Song song;

  _SongDataFrameState() {
    song = const Song(
        id: 0, title: "null", album: "null", artist: "null", length: "null");
    Timer.periodic(
        const Duration(milliseconds: 300), (Timer t) => setState(() {}));
  }

  Future<void> play() async {
    song = await Song.fetch_random();
    var songid = song.id;
    await widget.player.setUrl(// Load a URL
        'https://music.stschiff.de/songs/$songid'); // Schemes: (https: | file: | asset: )
    // await widget.player.setLoopMode(LoopMode.all);
    widget.player.play(); // Play without waiting for completion
  }

  void stop() async {
    widget.player.stop();
  }

  void downvoteskip() async {
    if (await song.downvote()) {
      Fluttertoast.showToast(
          msg: "Song downgevotet ⬇️",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    await play();
  }

  void upvote() async {
    var success = await song.upvote();
    print(success);
    if (success) {
      Fluttertoast.showToast(
          msg: "Song upgevotet ❤️",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.black,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(song.title),
          Text(song.artist),
          Text(song.album),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 100,
                    onPressed: play,
                    color: Colors.blueAccent.shade100,
                    child: Text(widget.player.playing ? "⏭️" : "▶️"),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 100,
                    onPressed: stop,
                    color: Colors.blueAccent.shade100,
                    child: const Text("⏹️"),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 100,
                    onPressed: upvote,
                    color: Colors.blueAccent.shade100,
                    child: const Text("💓"),
                  )),
              Container(
                  margin: const EdgeInsets.all(5.0),
                  child: MaterialButton(
                    height: 100,
                    onPressed: downvoteskip,
                    color: Colors.blueAccent.shade100,
                    child: const Text("🤮"),
                  )),
            ],
          ),
          Text(widget.player.position.toString()),
          Text(song.length),
        ],
      ),
    );
  }
}
