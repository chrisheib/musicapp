import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/disk_size.dart';
import 'package:musicapp/main.dart';
// import 'package:musicapp/network.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> downloadFile(String url, String dir, String filename) async {
  logger.info("download url: $url");
  logger.info("download dir: $dir");
  logger.info("download filename: $filename");

  await Permission.storage.request();

  if (await (File(join(dir, filename)).exists())) {
    logger.info("File already exists!");
    return true;
  }

  if (!await spaceAvailable()) {
    logger.info("No more space available!");
    return false;
  }

  //if (!await isUsingFastConnection()) {
  //  logger.info("Not using fast connection!");
  //  return false;
  //}

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
        logger.info('FILE PROGRESS $fileName, $progress');
      },
      onDownloadCompleted: (String path) {
        logger.info('FILE DOWNLOADED TO PATH: $path');
      },
      onDownloadError: (String error) {
        logger.info('DOWNLOAD ERROR: $error');
      });

  logger.info("after done");

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
  } on FileSystemException {
    // if rename fails, copy the source file and then delete it
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}
