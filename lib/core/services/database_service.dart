import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  static const _dbName = 'openmodels_chat.db';
  static const _dbVersion = 2;

  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, _dbName);

    return await openDatabase(
      pathString,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create sessions table
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        model_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        system_prompt_override TEXT
      )
    ''');

    // 2. Create messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        tokens_per_second REAL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    // 3. Create indices for buttery smooth paginated rendering
    await db.execute(
        'CREATE INDEX idx_messages_session ON chat_messages (session_id)');
    await db.execute(
        'CREATE INDEX idx_messages_timestamp ON chat_messages (timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_sessions_created ON chat_sessions (created_at DESC)');

    // 4. Create benchmarks table
    await db.execute('''
      CREATE TABLE benchmarks (
        id TEXT PRIMARY KEY,
        model_name TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        tokens_per_second REAL NOT NULL,
        prompt_eval_latency_ms INTEGER NOT NULL,
        total_generation_latency_ms INTEGER NOT NULL,
        ram_used_mb REAL NOT NULL
      )
    ''');

    // 5. Create file_contexts table
    await db.execute('''
      CREATE TABLE file_contexts (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        content TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS benchmarks (
          id TEXT PRIMARY KEY,
          model_name TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          tokens_per_second REAL NOT NULL,
          prompt_eval_latency_ms INTEGER NOT NULL,
          total_generation_latency_ms INTEGER NOT NULL,
          ram_used_mb REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS file_contexts (
          id TEXT PRIMARY KEY,
          filename TEXT NOT NULL,
          content TEXT NOT NULL,
          added_at TEXT NOT NULL
        )
      ''');
    }
  }

  // --- Chat Sessions CRUD ---

  Future<Map<String, dynamic>> createSession({
    required String modelName,
    String? systemPrompt,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final createdAt = DateTime.now().toIso8601String();

    final session = {
      'id': id,
      'model_name': modelName,
      'created_at': createdAt,
      'system_prompt_override': systemPrompt,
    };

    await db.insert('chat_sessions', session);
    return session;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    final sessions = await db.query('chat_sessions', orderBy: 'created_at DESC');
    final enriched = <Map<String, dynamic>>[];
    for (final session in sessions) {
      final msgCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM chat_messages WHERE session_id = ?',
        [session['id']],
      )) ?? 0;
      final lastMsg = await db.query(
        'chat_messages',
        where: 'session_id = ?',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      enriched.add({
        ...session,
        'message_count': msgCount,
        'last_message_preview': lastMsg.isNotEmpty
            ? (lastMsg.first['content'] as String).trim()
            : null,
      });
    }
    return enriched;
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'chat_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  // --- Chat Messages CRUD & Pagination ---

  Future<Map<String, dynamic>> insertMessage({
    required String sessionId,
    required String role,
    required String content,
    double? tokensPerSecond,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final timestamp = DateTime.now().toIso8601String();

    final message = {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'timestamp': timestamp,
      'tokens_per_second': tokensPerSecond,
    };

    await db.insert('chat_messages', message);
    return message;
  }

  // Paginated retrieval of messages (buttery-smooth 120Hz helper)
  Future<List<Map<String, dynamic>>> getMessagesPaginated({
    required String sessionId,
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }
}
