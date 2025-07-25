import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // ✅ package: 부분 오타 수정
import 'package:path/path.dart';

// (Routine, RoutineLog, ShiftType, WorkSchedule 모델은 이전과 동일)
class Routine {
  int? id;
  String name;
  String category;
  Routine({this.id, required this.name, required this.category});
  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'category': category};
  factory Routine.fromMap(Map<String, dynamic> map) =>
      Routine(id: map['id'], name: map['name'], category: map['category']);
}

class RoutineLog {
  int? id;
  final int routineId;
  final String date;
  bool isCompleted;
  RoutineLog(
      {this.id,
      required this.routineId,
      required this.date,
      required this.isCompleted});
  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'date': date,
        'is_completed': isCompleted ? 1 : 0
      };
}

class ShiftType {
  int? id;
  String name;
  String abbreviation;
  TimeOfDay startTime;
  TimeOfDay endTime;
  Color color;
  double nightHours;
  ShiftType(
      {this.id,
      required this.name,
      required this.abbreviation,
      required this.startTime,
      required this.endTime,
      required this.color,
      this.nightHours = 0.0});
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'start_time': '${startTime.hour}:${startTime.minute}',
        'end_time': '${endTime.hour}:${endTime.minute}',
        'color': color.value,
        'night_hours': nightHours
      };
  factory ShiftType.fromMap(Map<String, dynamic> map) {
    final st = map['start_time'].split(':');
    final et = map['end_time'].split(':');
    return ShiftType(
        id: map['id'],
        name: map['name'],
        abbreviation: map['abbreviation'],
        startTime: TimeOfDay(hour: int.parse(st[0]), minute: int.parse(st[1])),
        endTime: TimeOfDay(hour: int.parse(et[0]), minute: int.parse(et[1])),
        color: Color(map['color']),
        nightHours: map['night_hours'] ?? 0.0);
  }
}

class WorkSchedule {
  int? id;
  String startDate;
  String startTime;
  String endDate;
  String endTime;
  String pattern;
  WorkSchedule(
      {this.id,
      required this.startDate,
      required this.startTime,
      required this.endDate,
      required this.endTime,
      required this.pattern});
  Map<String, dynamic> toMap() => {
        'id': id,
        'start_date': startDate,
        'start_time': startTime,
        'end_date': endDate,
        'end_time': endTime,
        'pattern': pattern
      };
  factory WorkSchedule.fromMap(Map<String, dynamic> map) => WorkSchedule(
      id: map['id'],
      startDate: map['start_date'],
      startTime: map['start_time'],
      endDate: map['end_date'],
      endTime: map['end_time'],
      pattern: map['pattern']);
}

class DBHelper {
  static Database? _database;
  static const String dbName = 'work_schedule.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await openDatabase(path,
        version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertInitialRoutines(db);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS todos');
      await db.execute(
          '''CREATE TABLE routines(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT NOT NULL)''');
      await db.execute(
          '''CREATE TABLE routine_log(id INTEGER PRIMARY KEY AUTOINCREMENT, routine_id INTEGER, date TEXT NOT NULL, is_completed INTEGER NOT NULL, FOREIGN KEY (routine_id) REFERENCES routines (id))''');
      await _insertInitialRoutines(db);
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE shift_types ADD COLUMN night_hours REAL DEFAULT 0.0');
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(
        '''CREATE TABLE shift_types(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, abbreviation TEXT, start_time TEXT, end_time TEXT, color INTEGER, night_hours REAL DEFAULT 0.0)''');
    await db.execute(
        '''CREATE TABLE work_schedules(id INTEGER PRIMARY KEY AUTOINCREMENT, start_date TEXT, start_time TEXT, end_date TEXT, end_time TEXT, pattern TEXT)''');
    await db.execute(
        '''CREATE TABLE routines(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT NOT NULL)''');
    await db.execute(
        '''CREATE TABLE routine_log(id INTEGER PRIMARY KEY AUTOINCREMENT, routine_id INTEGER, date TEXT NOT NULL, is_completed INTEGER NOT NULL, FOREIGN KEY (routine_id) REFERENCES routines (id))''');
  }

  static Future<void> _insertInitialRoutines(Database db) async {
    final routines = [
      {'name': '30분 이상 운동하기', 'category': '건강 챙기기'},
      {'name': '건강한 식사하기', 'category': '건강 챙기기'},
      {'name': '햇빛 쬐기', 'category': '건강 챙기기'},
      {'name': '15분 독서하기', 'category': '마음 챙기기'},
      {'name': '짧은 명상하기', 'category': '마음 챙기기'},
      {'name': '감사일기 쓰기', 'category': '마음 챙기기'},
      {'name': '따뜻한 차 마시기', 'category': '숙면 돕기'}
    ];
    for (var routine in routines) {
      await db.insert('routines', routine);
    }
  }

  static Future<void> insertRoutine(Routine routine) async {
    final db = await database;
    await db.insert('routines', routine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routines');
    return List.generate(maps.length, (i) => Routine.fromMap(maps[i]));
  }

  static Future<void> updateRoutine(Routine routine) async {
    final db = await database;
    await db.update('routines', routine.toMap(),
        where: 'id = ?', whereArgs: [routine.id]);
  }

  static Future<void> deleteRoutine(int id) async {
    final db = await database;
    await db.delete('routine_log', where: 'routine_id = ?', whereArgs: [id]);
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<int, bool>> getRoutineLogForDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('routine_log', where: 'date = ?', whereArgs: [date]);
    return {for (var map in maps) map['routine_id']: map['is_completed'] == 1};
  }

  static Future<void> updateRoutineLog(
      int routineId, String date, bool isCompleted) async {
    final db = await database;
    final existing = await db.query('routine_log',
        where: 'routine_id = ? AND date = ?', whereArgs: [routineId, date]);
    if (existing.isNotEmpty) {
      await db.update('routine_log', {'is_completed': isCompleted ? 1 : 0},
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('routine_log', {
        'routine_id': routineId,
        'date': date,
        'is_completed': isCompleted ? 1 : 0
      });
    }
  }

  static Future<int> insertShiftType(ShiftType type) async {
    final db = await database;
    return await db.insert('shift_types', type.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ShiftType>> getAllShiftTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shift_types');
    return List.generate(maps.length, (i) => ShiftType.fromMap(maps[i]));
  }

  static Future<void> updateShiftType(ShiftType type) async {
    final db = await database;
    await db.update('shift_types', type.toMap(),
        where: 'id = ?', whereArgs: [type.id]);
  }

  static Future<int> insertWorkSchedule(WorkSchedule schedule) async {
    final db = await database;
    return await db.insert('work_schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<WorkSchedule>> getAllWorkSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('work_schedules');
    return List.generate(maps.length, (i) => WorkSchedule.fromMap(maps[i]));
  }

  static Future<void> updateWorkSchedule(WorkSchedule schedule) async {
    final db = await database;
    await db.update('work_schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
  }

  static Future<void> deleteWorkSchedule(int id) async {
    final db = await database;
    await db.delete('work_schedules', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteWorkSchedulesForDate(String dateString) async {
    final db = await database;
    await db.delete('work_schedules',
        where: 'start_date = ?', whereArgs: [dateString]);
  }

  static Future<void> clearAllSchedules() async {
    final db = await database;
    await db.delete('work_schedules');
  }
}
