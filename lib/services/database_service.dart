import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/sortie.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = join(await getDatabasesPath(), 'evangelisation.db');
    return await openDatabase(
      path,
      version: 2,
      onOpen: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      },
      onCreate: (db, v) async {
        await db.execute('''CREATE TABLE sorties(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          lieu TEXT NOT NULL,
          notes TEXT
        )''');
        await db.execute('''CREATE TABLE evangelisateurs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          sortie_id INTEGER NOT NULL,
          FOREIGN KEY(sortie_id) REFERENCES sorties(id) ON DELETE CASCADE
        )''');
        await db.execute('''CREATE TABLE personnes_touchees(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          contact TEXT,
          sortie_id INTEGER NOT NULL,
          FOREIGN KEY(sortie_id) REFERENCES sorties(id) ON DELETE CASCADE
        )''');
      },
    );
  }

  // ── SORTIES ──────────────────────────────────────────────────────────────

  Future<List<Sortie>> getSorties() async {
    final db = await database;
    final rows = await db.query('sorties', orderBy: 'date DESC');
    final sorties = rows.map((r) => Sortie.fromMap(r)).toList();
    for (final s in sorties) {
      s.evangelisateurs = await getEvangelisateurs(s.id!);
      s.personnesTouchees = await getPersonnesTouchees(s.id!);
    }
    return sorties;
  }

  Future<Sortie?> getSortie(int id) async {
    final db = await database;
    final rows = await db.query('sorties', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final s = Sortie.fromMap(rows.first);
    s.evangelisateurs = await getEvangelisateurs(id);
    s.personnesTouchees = await getPersonnesTouchees(id);
    return s;
  }

  Future<int> addSortie(Sortie sortie) async {
    final db = await database;
    return await db.insert('sorties', sortie.toMap());
  }

  Future<void> updateSortie(Sortie sortie) async {
    final db = await database;
    await db.update('sorties', sortie.toMap(),
        where: 'id=?', whereArgs: [sortie.id]);
  }

  Future<void> deleteSortie(int id) async {
    final db = await database;
    await db.delete('sorties', where: 'id=?', whereArgs: [id]);
  }

  // ── EVANGELISATEURS ──────────────────────────────────────────────────────

  Future<List<Evangelisateur>> getEvangelisateurs(int sortieId) async {
    final db = await database;
    final rows = await db.query('evangelisateurs',
        where: 'sortie_id=?', whereArgs: [sortieId]);
    return rows.map((r) => Evangelisateur.fromMap(r)).toList();
  }

  Future<void> replaceEvangelisateurs(
      int sortieId, List<String> noms) async {
    final db = await database;
    await db.delete('evangelisateurs',
        where: 'sortie_id=?', whereArgs: [sortieId]);
    for (final nom in noms) {
      if (nom.trim().isNotEmpty) {
        await db.insert(
            'evangelisateurs', {'nom': nom.trim(), 'sortie_id': sortieId});
      }
    }
  }

  // ── PERSONNES TOUCHEES ───────────────────────────────────────────────────

  Future<List<PersonneTouchee>> getPersonnesTouchees(int sortieId) async {
    final db = await database;
    final rows = await db.query('personnes_touchees',
        where: 'sortie_id=?', whereArgs: [sortieId]);
    return rows.map((r) => PersonneTouchee.fromMap(r)).toList();
  }

  Future<void> replacePersonnesTouchees(
      int sortieId, List<Map<String, String>> data) async {
    final db = await database;
    await db.delete('personnes_touchees',
        where: 'sortie_id=?', whereArgs: [sortieId]);
    for (final d in data) {
      if ((d['nom'] ?? '').trim().isNotEmpty) {
        await db.insert('personnes_touchees', {
          'nom': d['nom']!.trim(),
          'contact': d['contact']?.trim(),
          'sortie_id': sortieId,
        });
      }
    }
  }

  // ── STATS ────────────────────────────────────────────────────────────────

  Future<int> countSorties() async {
    final db = await database;
    final r =
        await db.rawQuery('SELECT COUNT(*) as c FROM sorties');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> countPersonnesTouchees() async {
    final db = await database;
    final r =
        await db.rawQuery('SELECT COUNT(*) as c FROM personnes_touchees');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> countEvangelisateursUniques() async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(DISTINCT LOWER(TRIM(nom))) as c FROM evangelisateurs');
    return (r.first['c'] as int?) ?? 0;
  }

  /// Participation : nom → nombre de sorties
  Future<List<Map<String, dynamic>>> getParticipationStats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT TRIM(nom) as nom, COUNT(*) as total
      FROM evangelisateurs
      GROUP BY LOWER(TRIM(nom))
      ORDER BY total DESC
      LIMIT 10
    ''');
  }

  /// Touches par sortie (pour graphique)
  // ── SETTINGS ────────────────────────────────────────────────────────────────

  Future<String?> getLogoPath() async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key=?', whereArgs: ['logo_path']);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setLogoPath(String? path) async {
    final db = await database;
    if (path == null) {
      await db.delete('settings', where: 'key=?', whereArgs: ['logo_path']);
    } else {
      await db.insert(
        'settings',
        {'key': 'logo_path', 'value': path},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTouchesParSortie() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.date, s.lieu, COUNT(pt.id) as touches
      FROM sorties s
      LEFT JOIN personnes_touchees pt ON pt.sortie_id = s.id
      GROUP BY s.id
      ORDER BY s.date ASC
    ''');
  }
}
