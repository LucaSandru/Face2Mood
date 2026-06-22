import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'mood_record.dart';


/// Handles all local SQLite database operations used by Face2Mood.
/// Stores mood records, user/person names, and manages database migrations.
class DatabaseService {

  // Singleton instance used to avoid opening multiple database connections.
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Returns the existing database connection or initializes it if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens the local SQLite database and applies creation or migration logic.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mood_database.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the initial database structure for mood records and saved people.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        primaryEmotion TEXT,
        confidence REAL,
        secondEmotion TEXT,
        secondConfidence REAL,
        thirdEmotion TEXT,
        thirdConfidence REAL,
        blendedColorHex TEXT,
        personName TEXT,
        userDescription TEXT,
        userDominantEmotion TEXT,
        allEmotionScores TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE people(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    await db.insert('people', {'name': 'You - Main User'});
  }

  /// Handles database schema upgrades when new fields are added in later versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

    // Version 2 introduced storage for the second and third predicted emotions.
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE moods ADD COLUMN secondEmotion TEXT');
      await db.execute('ALTER TABLE moods ADD COLUMN secondConfidence REAL');
      await db.execute('ALTER TABLE moods ADD COLUMN thirdEmotion TEXT');
      await db.execute('ALTER TABLE moods ADD COLUMN thirdConfidence REAL');
    }

    // Version 3 introduced user-provided mood context and selected emotion.
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE moods ADD COLUMN personName TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE moods ADD COLUMN userDescription TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE moods ADD COLUMN userDominantEmotion TEXT');
      } catch (_) {}
    }

    // Version 5 introduced the people table used for person filtering.
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS people(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE
        )
      ''');

      await db.insert(
        'people',
        {'name': 'You - Main User'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Version 6 introduced full emotion-score storage for all seven emotions.
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE moods ADD COLUMN allEmotionScores TEXT');
      } catch (_) {}
    }
  }


  /// Returns all saved people names, ordered alphabetically.
  Future<List<String>> getPeople() async {
    final db = await database;
    final result = await db.query(
      'people',
      orderBy: 'name ASC',
    );
    return result.map((row) => row['name'] as String).toList();
  }


  /// Adds a new person name if it is not empty and does not already exist.
  Future<void> addPerson(String name) async {
    final db = await database;
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    await db.insert(
      'people',
      {'name': cleanName},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  /// Inserts a new mood record and returns its generated database ID.
  Future<int> insertMood(MoodRecord record) async {
    final db = await database;
    return await db.insert('moods', record.toMap());
  }


  /// Retrieves all mood records ordered from newest to oldest.
  Future<List<MoodRecord>> getAllMoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('moods', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) {
      return MoodRecord.fromMap(maps[i]);
    });
  }


  /// Deletes all mood records and refreshes the people table.
  Future<void> clearAllMoods() async {
    final db = await database;
    await db.delete('moods');
    await syncPeopleWithMoods();
  }


  /// Removes people that are no longer associated with any mood record.
  Future<void> cleanUnusedPeople() async {
    final db = await database;
    await db.delete(
      'people',
      where: '''
      name != ? AND name NOT IN (
        SELECT DISTINCT personName FROM moods WHERE personName IS NOT NULL
      )
    ''',
      whereArgs: ['You - Main User'],
    );
  }


  /// Rebuilds the people table based on names currently used in mood records.
  Future<void> syncPeopleWithMoods() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('people');
      await txn.insert(
        'people',
        {'name': 'You - Main User'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      final rows = await txn.rawQuery('''
      SELECT DISTINCT personName 
      FROM moods 
      WHERE personName IS NOT NULL 
      AND TRIM(personName) != ''
      AND personName != 'You - Main User'
    ''');
      for (final row in rows) {
        final name = row['personName'] as String;
        await txn.insert(
          'people',
          {'name': name},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }


  /// Deletes a single mood record by its database ID.
  Future<void> deleteMood(int id) async {
    final db = await database;
    await db.delete(
      'moods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
