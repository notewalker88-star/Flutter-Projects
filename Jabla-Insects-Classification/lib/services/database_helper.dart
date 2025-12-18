import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'insect_history.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT,
        confidence REAL,
        imagePath TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<int> insertClassification(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('history', row);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    Database db = await database;
    return await db.query('history', orderBy: 'timestamp DESC');
  }

  Future<int> deleteHistoryItem(int id) async {
    Database db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    Database db = await database;
    await db.delete('history');
  }

  Future<List<Map<String, dynamic>>> getClassificationStats() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT label, COUNT(*) as count 
      FROM history 
      GROUP BY label 
      ORDER BY count DESC
    ''');
  }
}
