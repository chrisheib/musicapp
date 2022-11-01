import 'dart:convert';

import 'package:http/http.dart' as http;

class Song {
  final int id;
  final String title;
  final String album;
  final String artist;
  final String length;

  const Song({
    required this.id,
    required this.title,
    required this.album,
    required this.artist,
    required this.length,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['songname'],
      album: json['album'],
      artist: json['artist'],
      length: json['length'],
    );
  }

  static Future<Song> fetch_random() async {
    var response =
        await http.get(Uri.parse('https://music.stschiff.de/random_id'));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      int i = int.parse(response.body);
      return await Song.fetch(i);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  static Future<Song> fetch(int id) async {
    var response =
        await http.get(Uri.parse('https://music.stschiff.de/songdata/$id'));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var s = Song.fromJson(jsonDecode(response.body));
      // print(s);
      return s;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  Future<bool> upvote() async {
    var response =
        await http.get(Uri.parse('https://music.stschiff.de/upvote/$id'));
        return response.statusCode == 200;
  }

  Future<bool> downvote() async {
    var response =
        await http.get(Uri.parse('https://music.stschiff.de/downvote/$id'));
        return response.statusCode == 200;
  }
}
