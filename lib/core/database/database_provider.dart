import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

class DatabaseProvider {
  static AppDatabase? _database;

  static AppDatabase get database {
    _database ??= AppDatabase(_openConnection());
    return _database!;
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'parkflow.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
