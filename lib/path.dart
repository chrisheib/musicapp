import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getSongDir([int? id]) async {
  // var path = "/storage/emulated/0/Download/";
  // var appDocDir = await getExternalStorageDirectory();
  // var path = join(appDocDir!.path, 'songapp_songs');
  // var path = join(path, 'songapp_songs');
  var path = join(await getAppStorageBaseDir(), "music");
  if (id != null) {
    path = join(path, "$id.mp3");
  }

  return path;
}

Future<String> getAppStorageBaseDir() async {
  return (await getExternalStorageDirectory())!.path;
}

Future<String> getDownloadPath([String id = ""]) async {
  var path = "/storage/emulated/0/Download/";
  // var appDocDir = await getExternalStorageDirectory();
  // var path = join(appDocDir!.path, 'songapp_songs');
  // var path = join(path, 'songapp_songs');
  if (id.isNotEmpty) {
    path = join(path, "$id.mp3");
  }

  return path;
}
