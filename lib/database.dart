import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> getDbConnection() async {
  // Open the database and store the reference.
  return await openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'songs.db'),
    onUpgrade: (db, oldVersion, newVersion) async {
      print("OnUpdate:  $oldVersion -> $newVersion");
      if (oldVersion <= 3) {
        print("update 3");
        await db.execute("DROP TABLE IF EXISTS songs");
      }
      if (oldVersion <= 4) {
        print("update 4");
        await db.execute(
          """CREATE TABLE songs(
            id INTEGER PRIMARY KEY,
            title TEXT,
            album TEXT,
            artist TEXT,
            filename TEXT,
            length NUMBER,
            rating NUMBER
          )""",
        );
      }
      if (oldVersion <= 5) {
        print("update 5");
        await db.execute("DROP TABLE IF EXISTS songs");
        await db.execute(
          """CREATE TABLE songs(
            id INTEGER PRIMARY KEY,
            title TEXT,
            album TEXT,
            artist TEXT,
            length TEXT,
            filename TEXT,
            rating NUMBER
          )""",
        );
      }
      if (oldVersion <= 6) {
        print("update 6");
        await db.execute("ALTER TABLE songs ADD COLUMN downloaded INT");
      }
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 6,
  );
}
