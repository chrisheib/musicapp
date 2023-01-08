import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiple_random_choice/multiple_random_choice.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/song.dart';

Future<Song> localRandom(double scaling) async {
  var db = await getDbConnection();
  bool isDownloaded = false;
  Song? song;
  while (!isDownloaded) {
    final List<Map<String, dynamic>> songlistRes =
        await db.query('songs', where: "downloaded = 1 and rating > 0");
    if (songlistRes.isEmpty) {
      Fluttertoast.showToast(
          msg: "Scheinbar sind keine Songs heruntergeladen!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red.shade300,
          textColor: Colors.black,
          fontSize: 16.0);
      throw Exception("Scheinbar sind keine Songs heruntergeladen!");
    }
    var randSongId = getRandomId(songlistResToWeightMap(songlistRes, scaling));
    song = Song.fromJson(
        songlistRes.firstWhere((element) => element["id"] == randSongId));
    isDownloaded = await song.isDownloaded();
    if (!isDownloaded) {
      await db.execute(
          "UPDATE songs SET donwloaded = false WHERE id = ?", [song.id]);
    }
  }
  return song!;
}

Map<int, double> songlistResToWeightMap(List<dynamic> songs, double scaling) {
  return {
    for (var element in songs)
      element["id"] as int: pow(scaling, element["rating"] - 1) as double
  };
}

int getRandomId(Map<int, double> weights) {
  return randomMultipleWeightedChoice<int>(weights, 1, null).first;
}
