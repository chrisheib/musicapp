import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/disk_size.dart';
import 'package:musicapp/network.dart';
import 'package:path/path.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> downloadFile(String url, String dir, String filename) async {
  print(url);
  print(dir);
  print(filename);

  if (await File(join(dir, filename)).exists()) {
    return true;
  }

  await Permission.storage.request();
  if (!await spaceAvailable()) {
    return false;
  }

  if (!await isUsingFastConnection()) {
    return false;
  }

  Fluttertoast.showToast(
      msg: "Beginne Donwload $filename!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blue,
      textColor: Colors.black,
      fontSize: 16.0);

  var file = await FileDownloader.downloadFile(
      url: url,
      name: filename,
      onProgress: (fileName, progress) {
        print('FILE PROGRESS $fileName, $progress');
      },
      onDownloadCompleted: (String path) {
        print('FILE DOWNLOADED TO PATH: $path');
      },
      onDownloadError: (String error) {
        print('DOWNLOAD ERROR: $error');
      });

  print("after done");

  await moveFile(file!, join(dir, filename));
  bool success = await File(join(dir, filename)).exists();
  if (success) {
    Fluttertoast.showToast(
        msg: "Song $filename heruntergeladen!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.black,
        fontSize: 16.0);
  }
  return success;
}

Future<File> moveFile(File sourceFile, String newPath) async {
  try {
    // prefer using rename as it is probably faster
    return await sourceFile.rename(newPath);
  } on FileSystemException catch (e) {
    // if rename fails, copy the source file and then delete it
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}
