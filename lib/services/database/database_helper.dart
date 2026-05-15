import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/workout/workout.dart';
import '../../models/user/user_profile.dart';
import '../../models/workout/exercise.dart';
import '../../models/program/program.dart';
import '../../models/program/day_template.dart';
import '../../models/program/exercise_template.dart';
import '../../models/exercise/exercise_library.dart';
import '../../models/program/active_program.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fitness_app.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createProgramTables(db);
    }
    if (oldVersion < 3) {
      // Ensure exercises table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workoutId INTEGER,
          name TEXT,
          sets INTEGER,
          reps INTEGER,
          weight REAL,
          FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Ensure active_programs table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS active_programs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          templateId INTEGER,
          startDate TEXT,
          currentWeek INTEGER,
          isCompleted INTEGER,
          FOREIGN KEY (templateId) REFERENCES programs (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        date TEXT,
        durationMinutes INTEGER,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        weight REAL,
        height REAL,
        goal TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER,
        name TEXT,
        sets INTEGER,
        reps INTEGER,
        weight REAL,
        FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    await _createProgramTables(db);
  }

  Future<void> _createProgramTables(Database db) async {
    await db.execute('''
      CREATE TABLE programs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        durationWeeks INTEGER,
        startDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE day_templates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        programId INTEGER,
        dayOfWeek TEXT,
        routineName TEXT,
        FOREIGN KEY (programId) REFERENCES programs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_templates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dayTemplateId INTEGER,
        exerciseName TEXT,
        targetSets INTEGER,
        targetReps INTEGER,
        FOREIGN KEY (dayTemplateId) REFERENCES day_templates (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_library(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        isCustom INTEGER
      )
    ''');

    // Populate library with defaults
    final List<Map<String, dynamic>> defaults = [
      {'name': 'Bench Press', 'category': 'Chest', 'isCustom': 0},
      {'name': 'Squat', 'category': 'Legs', 'isCustom': 0},
      {'name': 'Deadlift', 'category': 'Back', 'isCustom': 0},
      {'name': 'Overhead Press', 'category': 'Shoulders', 'isCustom': 0},
      {'name': 'Pull Ups', 'category': 'Back', 'isCustom': 0},
    ];
    for (var item in defaults) {
      await db.insert('exercise_library', item);
    }
  }

  // Exercise Library Methods
  Future<int> insertLibraryExercise(ExerciseLibrary exercise) async {
    Database db = await database;
    return await db.insert('exercise_library', exercise.toMap());
  }

  Future<List<ExerciseLibrary>> getLibraryExercises() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('exercise_library', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => ExerciseLibrary.fromMap(maps[i]));
  }

  // Program Methods
  Future<int> insertProgram(Program program) async {
    Database db = await database;
    return await db.insert('programs', program.toMap());
  }

  Future<List<Program>> getPrograms() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('programs');
    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  Future<Program?> getProgramById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('programs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Program.fromMap(maps.first);
    return null;
  }

  Future<int> insertDayTemplate(DayTemplate template) async {
    Database db = await database;
    return await db.insert('day_templates', template.toMap());
  }

  Future<List<DayTemplate>> getDayTemplatesForProgram(int programId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('day_templates', where: 'programId = ?', whereArgs: [programId]);
    return List.generate(maps.length, (i) => DayTemplate.fromMap(maps[i]));
  }

  // Active Program Methods
  Future<int> enrollInProgram(ActiveProgram active) async {
    Database db = await database;
    return await db.insert('active_programs', active.toMap());
  }

  Future<List<ActiveProgram>> getActivePrograms() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('active_programs', where: 'isCompleted = 0');
    return List.generate(maps.length, (i) => ActiveProgram.fromMap(maps[i]));
  }

  Future<List<ActiveProgram>> getAllEnrolledPrograms() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('active_programs', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => ActiveProgram.fromMap(maps[i]));
  }

  Future<int> insertExerciseTemplate(ExerciseTemplate template) async {
    Database db = await database;
    return await db.insert('exercise_templates', template.toMap());
  }

  Future<List<ExerciseTemplate>> getExerciseTemplatesForDay(int dayTemplateId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('exercise_templates', where: 'dayTemplateId = ?', whereArgs: [dayTemplateId]);
    return List.generate(maps.length, (i) => ExerciseTemplate.fromMap(maps[i]));
  }

  // Exercise Methods
  Future<int> insertExercise(Exercise exercise) async {
    Database db = await database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercisesForWorkout(int workoutId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('exercises', where: 'workoutId = ?', whereArgs: [workoutId]);
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  // Profile Methods
  Future<UserProfile?> getProfile() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('profiles', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps[0]);
    }
    return null;
  }

  Future<int> insertProfile(UserProfile profile) async {
    Database db = await database;
    return await db.insert('profiles', profile.toMap());
  }

  Future<int> updateProfile(UserProfile profile) async {
    Database db = await database;
    return await db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  // CRUD Operations for Workouts
  Future<int> insertWorkout(Workout workout) async {
    Database db = await database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<List<Workout>> getWorkouts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('workouts', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return Workout.fromMap(maps[i]);
    });
  }

  Future<int> deleteWorkout(int id) async {
    Database db = await database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> getWorkoutCount() async {
    Database db = await database;
    final results = await db.rawQuery('SELECT COUNT(*) FROM workouts');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<Workout?> getLastWorkout() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Workout.fromMap(maps[0]);
    }
    return null;
  }

  // Delete Program (and its associated day_templates + exercise_templates)
  Future<void> deleteProgram(int programId) async {
    Database db = await database;
    // Get all day templates for this program
    final days = await db.query('day_templates', where: 'programId = ?', whereArgs: [programId]);
    for (var day in days) {
      await db.delete('exercise_templates', where: 'dayTemplateId = ?', whereArgs: [day['id']]);
    }
    await db.delete('day_templates', where: 'programId = ?', whereArgs: [programId]);
    await db.delete('active_programs', where: 'templateId = ?', whereArgs: [programId]);
    await db.delete('programs', where: 'id = ?', whereArgs: [programId]);
  }
}
