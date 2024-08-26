import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          isDone INTEGER,
          date TEXT
        )
      ''');
    } catch (e) {
      print('Error creating database: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('''
          ALTER TABLE todos ADD COLUMN date TEXT
        ''');
      } catch (e) {
        print('Error upgrading database: $e');
      }
    }
  }

  Future<int> insertTodo({
    required String title,
    required bool isDone,
    DateTime? date,
  }) async {
    final db = await database;
    final todo = {
      'title': title,
      'isDone': isDone ? 1 : 0,
      // If no date is provided, use today’s date
      'date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
    };
    try {
      return await db.insert('todos', todo);
    } catch (e) {
      print('Error inserting todo: $e');
      rethrow;
    }
  }

  // Separate method to insert a todo specifically for today's date
  Future<void> insertTodoForToday(String title, {bool isDone = false}) async {
    final db = await database;
    final todo = {
      'title': title,
      'isDone': isDone ? 1 : 0,
      'date': DateTime.now().toIso8601String().split('T')[0], // Only date part
    };
    try {
      await db.insert('todos', todo);
    } catch (e) {
      print('Error inserting todo for today: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTodos() async {
    final db = await database;
    try {
      return await db.query('todos');
    } catch (e) {
      print('Error fetching todos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTodosForDate(DateTime date) async {
    final db = await database;
    final formattedDate = date.toIso8601String().split('T')[0]; // Date only
    try {
      return await db.query(
        'todos',
        where: 'date = ?',
        whereArgs: [formattedDate],
      );
    } catch (e) {
      print('Error fetching todos for date: $e');
      return [];
    }
  }

  Future<int> updateTodo(Map<String, dynamic> todo) async {
    final db = await database;
    try {
      return await db.update(
        'todos',
        todo,
        where: 'id = ?',
        whereArgs: [todo['id']],
      );
    } catch (e) {
      print('Error updating todo: $e');
      rethrow;
    }
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting todo: $e');
      rethrow;
    }
  }
}
