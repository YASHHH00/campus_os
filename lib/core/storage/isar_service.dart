import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Centralized SQLite database service using sqflite.
///
/// Replaces Isar with a cross-platform SQLite solution that works with
/// Dart 3.12+. Manages database lifecycle, table creation, and provides
/// the [Database] instance to repositories.
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  factory DatabaseService() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text TEXT NOT NULL DEFAULT '',
        summary_text TEXT NOT NULL DEFAULT '',
        flashcard_json TEXT NOT NULL DEFAULT '[]',
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        detected_deadline TEXT,
        detected_amount TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        is_completed INTEGER NOT NULL DEFAULT 0,
        linked_note_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        total_amount REAL NOT NULL,
        participant_names TEXT NOT NULL DEFAULT '[]',
        split_amounts TEXT NOT NULL DEFAULT '[]',
        paid_by TEXT NOT NULL,
        receipt_image_path TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE lost_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supabase_id TEXT NOT NULL DEFAULT '',
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        image_path TEXT NOT NULL DEFAULT '',
        posted_by_user_id TEXT NOT NULL DEFAULT '',
        claimed_by_user_id TEXT,
        location TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        is_own_post INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE pending_extractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        extraction_type TEXT NOT NULL DEFAULT 'deadline'
      )
    ''');

    batch.execute('''
      CREATE TABLE pending_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image_path TEXT NOT NULL,
        location TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE INDEX idx_notes_created_at ON notes(created_at)
    ''');

    batch.execute('''
      CREATE INDEX idx_events_start_time ON events(start_time)
    ''');

    batch.execute('''
      CREATE INDEX idx_lost_items_status ON lost_items(status)
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migration logic goes here.
    // For now, version 1 is the only schema.
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllTables() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('notes');
    batch.delete('events');
    batch.delete('expenses');
    batch.delete('lost_items');
    batch.delete('pending_extractions');
    batch.delete('pending_posts');
    await batch.commit(noResult: true);
  }
}
