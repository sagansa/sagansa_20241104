import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../utils/json_utils.dart';

/// Database service untuk menyimpan log deteksi GPS palsu
class DetectionDatabase {
  static const String _databaseName = 'detection_logs.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'detection_logs';

  static Database? _database;
  static final DetectionDatabase _instance = DetectionDatabase._internal();

  factory DetectionDatabase() => _instance;
  DetectionDatabase._internal();

  /// Mendapatkan instance database
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    // SQLite tidak mendukung INDEX() di dalam CREATE TABLE (itu sintaks MySQL).
    // Index harus dibuat secara terpisah menggunakan CREATE INDEX.
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        location_data TEXT NOT NULL,
        validation_result TEXT NOT NULL,
        device_info TEXT NOT NULL,
        detection_details TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Buat index untuk mempercepat query umum
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_user_id ON $_tableName (user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_timestamp ON $_tableName (timestamp)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_synced_at ON $_tableName (synced_at)',
    );
  }

  /// Upgrade database jika diperlukan
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementasi upgrade schema jika diperlukan di masa depan
    if (oldVersion < 2) {
      // Contoh: ALTER TABLE untuk versi 2
      // await db.execute('ALTER TABLE $_tableName ADD COLUMN new_column TEXT');
    }
  }

  /// Menyimpan log deteksi ke database
  Future<void> insertLog(DetectionLog log) async {
    final db = await database;

    final data = {
      'id': log.id,
      'user_id': log.userId,
      'timestamp': log.timestamp.millisecondsSinceEpoch,
      'location_data': JsonUtils.serializeLocationData(log.location),
      'validation_result': JsonUtils.serializeValidationResult(log.result),
      'device_info': log.deviceInfo,
      'detection_details': JsonUtils.encodeToJson(log.detectionDetails),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced_at': null,
    };

    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil log berdasarkan ID
  Future<DetectionLog?> getLogById(String id) async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapToDetectionLog(results.first);
  }

  /// Mengambil log berdasarkan user ID dengan pagination
  Future<List<DetectionLog>> getLogsByUserId(
    String userId, {
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final results = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map(_mapToDetectionLog).toList();
  }

  /// Mengambil log yang belum disinkronisasi
  Future<List<DetectionLog>> getUnsyncedLogs({int limit = 100}) async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'synced_at IS NULL',
      orderBy: 'timestamp ASC',
      limit: limit,
    );

    return results.map(_mapToDetectionLog).toList();
  }

  /// Menandai log sebagai sudah disinkronisasi
  Future<void> markLogAsSynced(String logId) async {
    final db = await database;

    await db.update(
      _tableName,
      {'synced_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  /// Menandai beberapa log sebagai sudah disinkronisasi
  Future<void> markLogsAsSynced(List<String> logIds) async {
    if (logIds.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (final id in logIds) {
      batch.update(
        _tableName,
        {'synced_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit();
  }

  /// Menghapus log lama berdasarkan tanggal
  Future<int> deleteOldLogs(DateTime beforeDate) async {
    final db = await database;

    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [beforeDate.millisecondsSinceEpoch],
    );
  }

  /// Menghitung jumlah log untuk user tertentu
  Future<int> getLogCountByUserId(String userId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
      [userId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mendapatkan statistik deteksi untuk user tertentu
  Future<Map<String, dynamic>> getDetectionStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    // Total logs
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE $whereClause',
      whereArgs,
    );
    final totalLogs = Sqflite.firstIntValue(totalResult) ?? 0;

    // Menghitung valid/invalid dan rata-rata risk score dengan parsing JSON
    // di Dart (lebih andal dibanding SUBSTR/INSTR di SQL yang rapuh terhadap
    // format JSON, spasi, atau urutan key yang berbeda).
    final rows = await db.rawQuery(
      'SELECT validation_result FROM $_tableName WHERE $whereClause',
      whereArgs,
    );

    int validLogs = 0;
    double totalRisk = 0.0;
    int parsedCount = 0;

    for (final row in rows) {
      try {
        final result = JsonUtils.deserializeValidationResult(
          row['validation_result'] as String,
        );
        if (result.isValid) validLogs++;
        totalRisk += result.riskScore;
        parsedCount++;
      } catch (_) {
        // Abaikan baris yang gagal diparse agar statistik tetap dapat dihitung
      }
    }

    final int invalidLogs = totalLogs - validLogs;
    final double avgRiskScore = parsedCount > 0 ? totalRisk / parsedCount : 0.0;

    return {
      'totalLogs': totalLogs,
      'validLogs': validLogs,
      'invalidLogs': invalidLogs,
      'successRate': totalLogs > 0 ? validLogs / totalLogs : 0.0,
      'averageRiskScore': avgRiskScore,
    };
  }

  /// Menutup database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Mapping dari database row ke DetectionLog
  DetectionLog _mapToDetectionLog(Map<String, dynamic> row) {
    try {
      // Parse location data
      final locationData =
          JsonUtils.deserializeLocationData(row['location_data']);

      // Parse validation result
      final validationResult =
          JsonUtils.deserializeValidationResult(row['validation_result']);

      // Parse detection details
      final detectionDetails = JsonUtils.safeParseJson<Map<String, dynamic>>(
        row['detection_details'],
        (json) => json,
        <String, dynamic>{},
      );

      return DetectionLog(
        id: row['id'],
        userId: row['user_id'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp']),
        location: locationData,
        result: validationResult,
        deviceInfo: row['device_info'],
        detectionDetails: detectionDetails,
      );
    } catch (e) {
      // Fallback untuk data yang corrupt
      return DetectionLog(
        id: row['id'] ?? 'unknown',
        userId: row['user_id'] ?? 'unknown',
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] ?? 0),
        location: LocationData(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          altitude: 0.0,
          speed: 0.0,
          bearing: 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] ?? 0),
          provider: 'unknown',
        ),
        result: ValidationResult(
          isValid: false,
          riskScore: 1.0,
          flags: [],
          reason: 'Data parsing error',
          validatedAt:
              DateTime.fromMillisecondsSinceEpoch(row['timestamp'] ?? 0),
        ),
        deviceInfo: row['device_info'] ?? 'unknown',
        detectionDetails: {},
      );
    }
  }
}
