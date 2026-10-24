import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class DatabaseHelper {
  static const String _dbName = 'local_ai_chat.db';
  static const int _dbVersion = 1;

  static const String tableSessions = 'sessions';
  static const String tableMessages = 'messages';
  static const String tableContextMemory = 'context_memory';

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    return await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sessions table
    await db.execute('''
      CREATE TABLE $tableSessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        model_id TEXT NOT NULL,
        system_prompt TEXT NOT NULL
      )
    ''');

    // Messages table with cascade delete
    await db.execute('''
      CREATE TABLE $tableMessages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        model_name TEXT,
        latency_ms INTEGER,
        FOREIGN KEY (session_id) REFERENCES $tableSessions (id) ON DELETE CASCADE
      )
    ''');

    // Context memory table for long-term key-value caller details
    await db.execute('''
      CREATE TABLE $tableContextMemory (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $tableSessions (id) ON DELETE CASCADE
      )
    ''');

    // Create index for fast message querying by session
    await db.execute(
      'CREATE INDEX idx_messages_session_id ON $tableMessages(session_id)',
    );
  }

  // --- Session Operations ---

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSessions,
      orderBy: 'updated_at DESC',
    );

    final List<ChatSession> sessions = [];
    for (final map in maps) {
      final sessionId = map['id'] as String;
      final messages = await getMessagesForSession(sessionId);

      sessions.add(
        ChatSession(
          id: sessionId,
          title: map['title'] as String,
          createdAt: DateTime.parse(map['created_at'] as String),
          updatedAt: DateTime.parse(map['updated_at'] as String),
          messages: messages,
          modelId: map['model_id'] as String,
          systemPrompt: map['system_prompt'] as String,
        ),
      );
    }
    return sessions;
  }

  Future<void> insertSession(ChatSession session) async {
    final db = await database;
    await db.insert(
      tableSessions,
      {
        'id': session.id,
        'title': session.title,
        'created_at': session.createdAt.toIso8601String(),
        'updated_at': session.updatedAt.toIso8601String(),
        'model_id': session.modelId,
        'system_prompt': session.systemPrompt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSession(ChatSession session) async {
    final db = await database;
    await db.update(
      tableSessions,
      {
        'title': session.title,
        'updated_at': session.updatedAt.toIso8601String(),
        'model_id': session.modelId,
        'system_prompt': session.systemPrompt,
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete(
      tableSessions,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- Message Operations ---

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) {
      return ChatMessage(
        id: map['id'] as String,
        role: MessageRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => MessageRole.user,
        ),
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        modelName: map['model_name'] as String?,
        latencyMs: map['latency_ms'] as int?,
        isStreaming: false,
      );
    }).toList();
  }

  Future<void> insertMessage(String sessionId, ChatMessage message) async {
    final db = await database;
    await db.insert(
      tableMessages,
      {
        'id': message.id,
        'session_id': sessionId,
        'role': message.role.name,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'model_name': message.modelName,
        'latency_ms': message.latencyMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      tableMessages,
      {
        'content': message.content,
        'latency_ms': message.latencyMs,
      },
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> clearMessagesForSession(String sessionId) async {
    final db = await database;
    await db.delete(
      tableMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- Context Memory Operations ---

  Future<void> saveContextFact(String sessionId, String key, String value) async {
    final db = await database;
    await db.insert(
      tableContextMemory,
      {
        'id': '${sessionId}_$key',
        'session_id': sessionId,
        'key': key,
        'value': value,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getContextFacts(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableContextMemory,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    final Map<String, String> facts = {};
    for (final map in maps) {
      facts[map['key'] as String] = map['value'] as String;
    }
    return facts;
  }
}
