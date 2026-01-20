import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/run_model.dart';


class RunDatabase {
static Database? _db;


static Future<Database> get database async {
if (_db != null) return _db!;
final path = join(await getDatabasesPath(), 'runflow.db');
_db = await openDatabase(path, version: 1, onCreate: (db, v) {
db.execute('''
CREATE TABLE runs(
id INTEGER PRIMARY KEY AUTOINCREMENT,
distance REAL,
duration INTEGER,
date TEXT
)
''');
});
return _db!;
}


static Future<void> insertRun(RunModel run) async {
final db = await database;
await db.insert('runs', run.toMap());
}


static Future<List<RunModel>> getRuns() async {
final db = await database;
final result = await db.query('runs', orderBy: 'id DESC');
return result.map((e) => RunModel.fromMap(e)).toList();
}
}