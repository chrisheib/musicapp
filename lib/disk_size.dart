import 'dart:io';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:musicapp/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<double> getFreeSpace() async {
  double? diskSpace = 0;
  diskSpace = await DiskSpace.getFreeDiskSpace;
  logger.info(diskSpace);

  List<Directory> directories;
  Map<Directory, double> directorySpace = {};

  await Permission.storage.request();
  await Permission.manageExternalStorage.request();

  directories =
      await getExternalStorageDirectories(type: StorageDirectory.music).then(
    (list) async => list ?? [await getApplicationDocumentsDirectory()],
  );

  var availableSpace = 0.0;

  for (var directory in directories) {
    var space = await DiskSpace.getFreeDiskSpaceForPath(directory.path);
    availableSpace += space ?? 0;
    directorySpace.addEntries([MapEntry(directory, space ?? 0)]);
  }

  logger.info("Directory Space: $directorySpace");
  logger.info("Available Space: $availableSpace");

  // if (!mounted) return;

  // setState(() {
  //   _diskSpace = diskSpace;
  //   _directorySpace = directorySpace;
  // });

  return availableSpace;
}

Future<bool> spaceAvailable() async {
  var space = await getFreeSpace();
  return space > 100;
}
