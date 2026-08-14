import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/specific_gravity_record.dart';

/// Database service untuk menyimpan riwayat perhitungan Berat Jenis (sqflite).
///
/// Meniru pola [DetectionDatabase]: singleton, lazy init, CRUD sederhana.
class SpecificGravityDatabase {
  static const String _databaseName = 'specific_gravity.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'specific_gravity_records';

  static Database? _database;
  static final SpecificGravityDatabase _instance =
      SpecificGravityDatabase._internal();

  factory SpecificGravityDatabase() => _instance;
  SpecificGravityDatabase._internal();

  /// Mendapatkan instance database.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        gram_per_liter REAL NOT NULL,
        total_kg REAL NOT NULL,
        additional_gram REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  /// Menyimpan entri riwayat berat jenis.
  Future<void> insertRecord(SpecificGravityRecord record) async {
    final db = await database;
    await db.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua entri, terbaru lebih dulu (timestamp DESC).
  Future<List<SpecificGravityRecord>> getAllRecords() async {
    final db = await database;
    final results = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );
    return results.map(SpecificGravityRecord.fromMap).toList();
  }

  /// Menghapus entri berdasarkan id.
  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menutup database.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
