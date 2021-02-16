import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:encrypt/encrypt.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {
  final String _master = "sqlite_master";

  final String name;

  final Map<String, String> tableNamesFormats;

  Database _db;

  DatabaseHandler.internal(
    this.name, {
    this.tableNamesFormats,
  });

  static final DatabaseHandler userData =
      DatabaseHandler.internal("userData", tableNamesFormats: {
    "Users": "username TEXT, name TEXT, gender TEXT, dob TEXT",
  });

  static final DatabaseHandler testData = DatabaseHandler.internal("testData");

  Future<Database> get() async {
    http.Response res = await http.get("https://symplifybucket.s3.us-east-1.amazonaws.com");
    print(res.body);
    _db ??= await _init();
    return _db;
  }

  Future<Database> _init({rep = 0}) async {
    try {
      await Directory(await getDatabasesPath()).create(recursive: true);
    } catch (_) {
      return null;
    }
    final db = await openDatabase(await _getPath(), version: 1,
        onCreate: (db, version) {
      if (tableNamesFormats != null)
        for (String key in tableNamesFormats.keys)
          addTable(key, tableNamesFormats[key]);
    });
    if (db.isOpen)
      return db;
    else {
      deleteDatabase(await _getPath());
      if (rep > 5) return null;
      return null;
    }
  }

  Future<List<String>> getAllTableNames() async {
    Iterable<String> iterable;
    try {
      iterable = await ((await get())
              .query(_master, where: 'type = ?', whereArgs: ['table']))
          .then((value) => value.map((row) => row['name'] as String));
    } catch (e) {
      return null;
    }
    List<String> ret = [];
    for (String value in iterable) {
      final String eval = value;
      ret.add(eval);
    }
    return ret;
  }

  Future<List<Map<String, String>>> getTable(String name) async {
    List<Map<String, dynamic>> list;
    try {
      list = (await (await get()).query(name));
    } catch (e) {
      return null;
    }
    List<Map<String, String>> res = [];
    for (Map<String, dynamic> map in list) {
      Map<String, String> decMap = Map();
      for (String key in map.keys)
        if (map[key] is String)
          decMap[key] = map[key] as String;
      res.add(decMap);
    }
    return res;
  }

  Future<void> deleteTable(String name) async {
    await (await get())
        .execute("DROP TABLE IF EXISTS $name");
  }

  Future<void> addTable(String name, String tableFormat) async {
    await (await get()).execute("CREATE TABLE IF NOT EXISTS " +
        name +
        "(" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        tableFormat +
        ")");
  }

  Future<void> insert(String tableName, Map<String, String> data) async {
    Map<String, String> inserted = Map();
    for (String key in data.keys)
      inserted[key] = data[key];
    (await get()).insert(tableName, inserted);
  }

  Future<void> delete(String tableName, String field, String check) async {
    (await get()).delete(tableName,
        where: "$field = ?", whereArgs: [check]);
  }

  Future<String> _getPath() async {
    final String databasePath = await getDatabasesPath();
    return "$databasePath$name.db";
  }

  Future<String> get _key async => (Platform.isIOS
          ? (await DeviceInfoPlugin().iosInfo).identifierForVendor
          : (await DeviceInfoPlugin().androidInfo).androidId)
      .substring(0, 16);

  static final IV _iv = IV.fromSecureRandom(6);

  Future<Encrypter> get _encrypt async =>
      Encrypter(AES(Key.fromUtf8(await _key)));

  Future<String> _encryptString(String input) async {
    return (await _encrypt).encrypt(input, iv: _iv).base16;
  }

  Future<String> _decryptString(String input) async {
    return (await _encrypt).decrypt16(input, iv: _iv);
  }

}
