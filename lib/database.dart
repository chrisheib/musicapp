import 'package:musicapp/main.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> getDbConnection() async {
  // Open the database and store the reference.
  return await openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'songs2.db'),
    onUpgrade: (db, oldVersion, newVersion) async {
      logger.info("OnUpdate:  $oldVersion -> $newVersion");
      if (oldVersion <= 3) {
        logger.info("update 3");
        await db.execute("DROP TABLE IF EXISTS songs");
      }
      if (oldVersion <= 4) {
        logger.info("update 4");
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
        logger.info("update 5");
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
        await db.execute("ALTER TABLE songs ADD COLUMN downloaded INT");
      }
      if (oldVersion <= 6) {
        logger.info("update 6");
        await db.execute("""CREATE TABLE config(
            ckey TEXT PRIMARY KEY,
            value_text TEXT,
            value_num REAL
          )""");
      }
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 7,
  );
}

Future<String?> getConfigStr(String key) async {
  var db = await getDbConnection();
  var res = await db.query("config", where: "ckey = ?", whereArgs: [key]);

  if (res.isEmpty) {
    return null;
  }
  if (res[0]["value_text"] == null) {
    return null;
  }
  return res[0]["value_text"].toString();
}

Future<double?> getConfigDouble(String key) async {
  var db = await getDbConnection();
  var res = await db.query("config", where: "ckey = ?", whereArgs: [key]);
  if (res.isEmpty) {
    return null;
  }
  if (res[0]["value_num"] == null) {
    return null;
  }
  return double.tryParse(res[0]["value_num"].toString());
}

void setConfigDouble(String key, double value) async {
  var db = await getDbConnection();
  await db.execute(
      """INSERT OR REPLACE INTO config (ckey, value_num) values (?, ?)""",
      [key, value]);
}

void setConfigStr(String key, String value) async {
  var db = await getDbConnection();
  await db.execute(
      """INSERT OR REPLACE INTO config (ckey, value_text) values (?, ?)""",
      [key, value]);
}
