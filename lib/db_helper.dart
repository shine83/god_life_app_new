import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ShiftType {
  int? id;
  String name;
  String abbreviation;
  TimeOfDay startTime;
  TimeOfDay endTime;
  Color color;

  ShiftType({
    this.id,
    required this.name,
    required this.abbreviation,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'color': color.value,
    };
  }

  factory ShiftType.fromMap(Map<String, dynamic> map) {
    List<String> start = map['startTime'].split(':');
    List<String> end = map['endTime'].split(':');
    return ShiftType(
      id: map['id'],
      name: map['name'],
      abbreviation: map['abbreviation'],
      startTime: TimeOfDay(
        hour: int.parse(start[0]),
        minute: int.parse(start[1]),
      ),
      endTime: TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1])),
      color: Color(map['color']),
    );
  }
}

class WorkSchedule {
  final int? id;
  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String pattern;

  WorkSchedule({
    this.id,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.pattern,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
      'pattern': pattern,
    };
  }

  factory WorkSchedule.fromMap(Map<String, dynamic> map) {
    return WorkSchedule(
      id: map['id'],
      startDate: map['startDate'],
      startTime: map['startTime'],
      endDate: map['endDate'],
      endTime: map['endTime'],
      pattern: map['pattern'],
    );
  }
}

class DBHelper {
  static Database? _db;

  static Future<void> initDB() async {
    if (_db != null) return;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'work_schedule_v3.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE work_schedule(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startDate TEXT, startTime TEXT,
            endDate TEXT, endTime TEXT,
            pattern TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shift_types(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            abbreviation TEXT UNIQUE,
            startTime TEXT, endTime TEXT,
            color INTEGER
          )
        ''');
      },
      version: 1,
    );
  }

  static Future<int> insertShiftType(ShiftType type) async {
    await initDB();
    return await _db!.insert(
      'shift_types',
      type.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ShiftType>> getAllShiftTypes() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _db!.query('shift_types');
    if (maps.isEmpty) {
      return [
        ShiftType(
          name: '주간',
          abbreviation: '주',
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          color: Colors.blue,
        ),
        ShiftType(
          name: '오후',
          abbreviation: '오',
          startTime: const TimeOfDay(hour: 15, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 0),
          color: Colors.orange,
        ),
        ShiftType(
          name: '야간',
          abbreviation: '야',
          startTime: const TimeOfDay(hour: 23, minute: 0),
          endTime: const TimeOfDay(hour: 7, minute: 0),
          color: Colors.red,
        ),
      ];
    }
    return List.generate(maps.length, (i) => ShiftType.fromMap(maps[i]));
  }

  static Future<void> updateShiftType(ShiftType type) async {
    await initDB();
    await _db!.update(
      'shift_types',
      type.toMap(),
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  static Future<void> deleteShiftType(int id) async {
    await initDB();
    await _db!.delete('shift_types', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertWorkSchedule(WorkSchedule schedule) async {
    await initDB();
    return await _db!.insert(
      'work_schedule',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<WorkSchedule>> getAllWorkSchedules() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _db!.query('work_schedule');
    return List.generate(maps.length, (i) => WorkSchedule.fromMap(maps[i]));
  }

  static Future<int> updateWorkSchedule(WorkSchedule schedule) async {
    await initDB();
    return await _db!.update(
      'work_schedule',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  static Future<void> deleteWorkSchedule(int id) async {
    await initDB();
    await _db!.delete('work_schedule', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllSchedules() async {
    await initDB();
    await _db!.delete('work_schedule');
  }
}
