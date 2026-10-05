import 'package:sqflite/sqflite.dart';

import '../models/transcription_job.dart';
import 'database_service.dart';

class TranscriptionRepository {
  TranscriptionRepository._();
  static final TranscriptionRepository instance = TranscriptionRepository._();

  static const _table = 'transcriptions';

  Future<Database> get _db async => DatabaseService().database;

  Future<void> ensureTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_audio_path TEXT NOT NULL,
        stored_audio_path TEXT,
        conversation_id TEXT,
        options_json TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0,
        progress_label TEXT,
        plain_text TEXT,
        srt_text TEXT,
        segments_json TEXT,
        duration_ms INTEGER,
        error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> upsert(TranscriptionJob job) async {
    await ensureTable();
    final db = await _db;
    await db.insert(
      _table,
      job.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TranscriptionJob?> getById(String id) async {
    await ensureTable();
    final db = await _db;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TranscriptionJob.fromDbRow(rows.first);
  }

  Future<List<TranscriptionJob>> listAll() async {
    await ensureTable();
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(TranscriptionJob.fromDbRow).toList();
  }

  Future<void> delete(String id) async {
    await ensureTable();
    final db = await _db;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
