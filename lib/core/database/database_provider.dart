import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

class DatabaseProvider {
  static AppDatabase? _database;

  static const _dbKeyName = 'parkflow_db_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Returns the singleton encrypted database instance.
  static Future<AppDatabase> getDatabase() async {
    if (_database != null) return _database!;
    _database = AppDatabase(await _openEncryptedConnection());
    return _database!;
  }

  /// Opens the database with SQLCipher encryption.
  /// The encryption key is generated once and stored in secure storage.
  static Future<LazyDatabase> _openEncryptedConnection() async {
    final key = await _getOrCreateEncryptionKey();
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'parkflow.db'));
      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // SQLCipher: set the encryption key before any other operation
          rawDb.execute("PRAGMA key = '$key'");
          // Harden: use 256-bit AES and 256000 KDF iterations (SQLCipher 4 default)
          rawDb.execute('PRAGMA cipher_compatibility = 4');
        },
      );
    });
  }

  /// Retrieves the existing encryption key or generates a new 64-char hex key.
  static Future<String> _getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: _dbKeyName);
    if (existing != null && existing.length == 64) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _dbKeyName, value: key);
    return key;
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
