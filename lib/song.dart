import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart';
import 'package:musicapp/database.dart';
import 'package:musicapp/downloader.dart';
import 'package:musicapp/main.dart';
import 'package:musicapp/network.dart';
import 'package:musicapp/path.dart';
import 'package:musicapp/random.dart';
import 'package:sqflite/sqflite.dart';

// {
//  "id":2861,
//  "path":"E:\\Musik\\Jan Hegenberg\\DEMOtape\\22 Knallwach.mp3",
//  "filename":"22 Knallwach.mp3",
//  "songname":"Knallwach-Hymne",
//  "artist":"Jan Hegenberg :: www.janhegenberg.de :: powererd by Levicom",
//  "album":"DEMOtape",
//  "length":"3:27",
//  "seconds":207,
//  "rating":3,
//  "vote":0,
//  "times_played":1
// }

class Song {
  final int id;
  final String title;
  final String album;
  final String artist;
  final String filename;
  final String length;
  int rating;
  bool upvoted = false;
  int downloaded;

  Song(
      {required this.id,
      required this.title,
      required this.album,
      required this.artist,
      required this.filename,
      required this.length,
      required this.rating,
      required this.downloaded});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['songname'] ?? "",
      album: json['album'] ?? "",
      artist: json['artist'] ?? "",
      length: json['length'] ?? "--:--",
      filename: json['filename'] ?? "",
      rating: json['rating'] ?? 0,
      downloaded: json['downloaded'] ?? 0,
    );
  }

  static Future<Song> fetchRandom(Database db, {double? scale}) async {
    // logger.info(await isConnected());
    if (await isConnected()) {
      Response response;
      if (scale == null) {
        logger.info("fetching with default scaling");
        response = await get(Uri.parse('https://music.stschiff.de/random_id'));
      } else {
        var scaleStr = scale.toStringAsFixed(1);
        logger.info("fetching with scaling $scaleStr");
        response = await get(
            Uri.parse('https://music.stschiff.de/random_id/$scaleStr'));
      }
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        int i = int.parse(response.body);
        return await Song.fetch(i);
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to fetch random');
      }
    } else {
      return await localRandom(scale ?? 3);
    }
  }

  static Future<Song> fetch(int id) async {
    var response =
        await get(Uri.parse('https://music.stschiff.de/songdata/$id'));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var s = Song.fromJson(jsonDecode(response.body));
      s.downloaded = await s.isDownloaded() ? 1 : 0;
      return s;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  Future<bool> upvote() async {
    var response = await get(Uri.parse('https://music.stschiff.de/upvote/$id'));
    var success = response.statusCode == 200;
    if (success) {
      upvoted = true;
      rating += 1;
    }
    return success;
  }

  Future<bool> downvote() async {
    var response =
        await get(Uri.parse('https://music.stschiff.de/downvote/$id'));
    var success = response.statusCode == 200;
    if (success) {
      upvoted = false;
      rating -= 1;
    }
    return success;
  }

  Future<bool> download() async {
    logger.info("Start download $id");
    downloaded = (await downloadFile('https://music.stschiff.de/songs/$id',
            await getSongDir(), "$id.mp3"))
        ? 1
        : 0;
    logger.info("Finished download $id: $downloaded");
    var db = await getDbConnection();
    await db.execute(
        "UPDATE songs set downloaded = ? where id = ?", [downloaded, id]);
    return downloaded == 1;
  }

  Future<bool> isDownloaded() async {
    return await File(await getSongDir(id.toString())).exists();
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "album": album,
      "artist": artist,
      "filename": filename,
      "length": length,
      "rating": rating,
      "downloaded": downloaded
    };
  }

  Future<void> saveToDb(Database db) async {
    await db.insert(
      'songs',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void saveToDbBatch(Batch db) {
    db.insert(
      'songs',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      album: album,
      title: title.isEmpty ? filename : title,
      artist: artist,
      rating: const Rating.newThumbRating(false),
      extras: {"rating": rating},
    );
  }
}
