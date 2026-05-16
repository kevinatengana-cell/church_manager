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
      version: 4,
      onOpen: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE sorties ADD COLUMN is_imported INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE sorties ADD COLUMN sender_name TEXT');
        }
      },
      onCreate: (db, v) async {
        await db.execute('''CREATE TABLE sorties(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          lieu TEXT NOT NULL,
          notes TEXT,
          is_imported INTEGER DEFAULT 0,
          sender_name TEXT
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
        // CORRECTION: settings manquait dans onCreate → table absente sur install fraîche
        await db.execute('''CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT
        )''');
      },
    );
  }

  // ── SORTIES ──────────────────────────────────────────────────────────────

  Future<List<Sortie>> getSorties({bool imported = false}) async {
    final db = await database;
    final rows = await db.query('sorties', where: 'is_imported=?', whereArgs: [imported ? 1 : 0], orderBy: 'date DESC');
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
    final rows = await db
        .query('evangelisateurs', where: 'sortie_id=?', whereArgs: [sortieId]);
    return rows.map((r) => Evangelisateur.fromMap(r)).toList();
  }

  Future<void> replaceEvangelisateurs(int sortieId, List<String> noms) async {
    final db = await database;
    await db
        .delete('evangelisateurs', where: 'sortie_id=?', whereArgs: [sortieId]);
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
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM sorties');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> countPersonnesTouchees() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM personnes_touchees');
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

  /// Assiduité par lieu d'évangélisation
  Future<Map<String, dynamic>> getAssiduiteParLieu(String lieu) async {
    final db = await database;
    
    final r1 = await db.rawQuery('SELECT COUNT(*) as c FROM sorties WHERE UPPER(TRIM(lieu)) = ?', [lieu.toUpperCase()]);
    final totalSorties = (r1.first['c'] as int?) ?? 0;
    
    final r2 = await db.rawQuery('''
      SELECT TRIM(e.nom) as nom, COUNT(*) as total
      FROM evangelisateurs e
      INNER JOIN sorties s ON e.sortie_id = s.id
      WHERE UPPER(TRIM(s.lieu)) = ?
      GROUP BY LOWER(TRIM(e.nom))
      ORDER BY total DESC
    ''', [lieu.toUpperCase()]);
    
    return {
      'totalSorties': totalSorties,
      'participation': r2,
    };
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

  Future<String?> getOwnerName() async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key=?', whereArgs: ['owner_name']);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setOwnerName(String? name) async {
    final db = await database;
    if (name == null || name.trim().isEmpty) {
      await db.delete('settings', where: 'key=?', whereArgs: ['owner_name']);
    } else {
      await db.insert(
        'settings',
        {'key': 'owner_name', 'value': name.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Stats for a specific evangelist (Owner)
  Future<Map<String, int>> getOwnerImpact(String ownerName) async {
    final db = await database;
    final nameLower = ownerName.trim().toLowerCase();

    // Sorties participées
    final sortiesRes = await db.rawQuery('''
      SELECT COUNT(DISTINCT sortie_id) as c 
      FROM evangelisateurs 
      WHERE LOWER(TRIM(nom)) = ?
    ''', [nameLower]);
    final sorties = (sortiesRes.first['c'] as int?) ?? 0;

    // Personnes touchées lors des sorties où l'owner était présent
    // OU on peut compter uniquement les personnes touchées globalement pour ces sorties
    final touchesRes = await db.rawQuery('''
      SELECT COUNT(pt.id) as c
      FROM personnes_touchees pt
      INNER JOIN evangelisateurs e ON e.sortie_id = pt.sortie_id
      WHERE LOWER(TRIM(e.nom)) = ?
    ''', [nameLower]);
    final touches = (touchesRes.first['c'] as int?) ?? 0;

    return {
      'sorties': sorties,
      'touches': touches,
    };
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

  /// Stats par lieu
  Future<List<Map<String, dynamic>>> getStatsByLieu() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT UPPER(TRIM(s.lieu)) as lieu, COUNT(DISTINCT s.id) as total_sorties, COUNT(pt.id) as touches
      FROM sorties s
      LEFT JOIN personnes_touchees pt ON pt.sortie_id = s.id
      GROUP BY UPPER(TRIM(s.lieu))
      ORDER BY touches DESC
    ''');
  }

  Future<List<String>> getLieux() async {
    final db = await database;
    final r = await db.rawQuery('SELECT DISTINCT UPPER(TRIM(lieu)) as lieu FROM sorties ORDER BY lieu');
    return r.map((e) => e['lieu'] as String).toList();
  }

  Future<List<String>> getEvangelistesList() async {
    final db = await database;
    final r = await db.rawQuery('SELECT DISTINCT UPPER(TRIM(nom)) as nom FROM evangelisateurs ORDER BY nom');
    return r.map((e) => e['nom'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getEvolutionParLieu(String lieu) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.date, COUNT(pt.id) as touches
      FROM sorties s
      LEFT JOIN personnes_touchees pt ON pt.sortie_id = s.id
      WHERE UPPER(TRIM(s.lieu)) = ?
      GROUP BY s.id
      ORDER BY s.date ASC
    ''', [lieu.toUpperCase()]);
  }

  Future<Map<String, List<Map<String, dynamic>>>> getEvolutionAllLieux() async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT UPPER(TRIM(s.lieu)) as lieu, s.date, COUNT(pt.id) as touches
      FROM sorties s
      LEFT JOIN personnes_touchees pt ON pt.sortie_id = s.id
      GROUP BY s.id
      ORDER BY s.date ASC
    ''');
    
    final datesQuery = await db.rawQuery('SELECT DISTINCT date FROM sorties ORDER BY date ASC');
    final List<String> allDates = datesQuery.map((d) => d['date'] as String).toList();

    final Map<String, List<Map<String, dynamic>>> result = {};
    for (var row in r) {
      final l = row['lieu'] as String;
      if (!result.containsKey(l)) result[l] = [];
      
      final dateStr = row['date'] as String;
      final xIndex = allDates.indexOf(dateStr);
      
      result[l]!.add({
        'x': xIndex,
        'date': dateStr,
        'touches': row['touches'],
      });
    }
    
    // On va aussi injecter allDates dans la map de retour pour faciliter l'axe X
    result['__dates__'] = allDates.map((e) => {'date': e}).toList();
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getEvolutionParEvangeliste(String nom) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.date, COUNT(pt.id) as touches
      FROM sorties s
      INNER JOIN evangelisateurs e ON e.sortie_id = s.id AND UPPER(TRIM(e.nom)) = ?
      LEFT JOIN personnes_touchees pt ON pt.sortie_id = s.id
      GROUP BY s.id
      ORDER BY s.date ASC
    ''', [nom.toUpperCase()]);
  }
}
