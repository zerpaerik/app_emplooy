import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emplooy_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const boolType = 'INTEGER';

    await db.execute('''
      CREATE TABLE workday_online (
        id $intType PRIMARY KEY,
        workday_id $intType,
        clock_in_init $textType,
        clock_in_fin $textType,
        clock_out_init $textType,
        clock_out_fin $textType,
        clock_in_location $textType,
        clock_out_location $textType,
        has_clockin $boolType DEFAULT 0,
        has_clockout $boolType DEFAULT 0,
        default_init $textType,
        default_exit $textType,
        ult_clock $textType,
        ultclokout $textType,
        sultclock $textType,
        sultclokout $textType,
        current_session_in $intType,
        current_session_out $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE clock_sessions (
        id $idType,
        workday_id $intType NOT NULL,
        supervisor_id $textType NOT NULL,
        supervisor_name $textType,
        session_start_time $textType NOT NULL,
        clock_type $textType NOT NULL,
        workers_count $intType DEFAULT 0,
        is_auto_mode $boolType DEFAULT 0,
        created_at $textType NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scanned_workers (
        id $idType,
        session_id $intType NOT NULL,
        worker_id $intType NOT NULL,
        worker_btn_id $textType NOT NULL,
        worker_name $textType,
        clock_time $textType NOT NULL,
        clock_type $textType NOT NULL,
        location $textType,
        scanned_at $textType NOT NULL,
        FOREIGN KEY (session_id) REFERENCES clock_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.insert('workday_online', {
      'id': 1,
      'workday_id': null,
      'ult_clock': '',
      'ultclokout': '',
      'sultclock': '',
      'sultclokout': '',
      'current_session_in': null,
      'current_session_out': null,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
