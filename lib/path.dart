import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

Future<String> getSongDir([String id = ""]) async {
  // var path = "/storage/emulated/0/Download/";
  // var appDocDir = await getExternalStorageDirectory();
  // var path = join(appDocDir!.path, 'songapp_songs');
  // var path = join(path, 'songapp_songs');
  var dirs = await getExternalStorageDirectories(type: StorageDirectory.music);
  var path = dirs![0].path;
  if (id.isNotEmpty) {
    path = join(path, "$id.mp3");
  }

  return path;
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
