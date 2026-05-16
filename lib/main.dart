import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sorties_screen.dart';
import 'screens/stats_screen.dart';
import 'services/import_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const EvangelisationApp());
}

class EvangelisationApp extends StatelessWidget {
  const EvangelisationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Évangélisation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavScreen(),
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({Key? key}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _idx = 0;
  final _importService = ImportService();

  @override
  void initState() {
    super.initState();
    _ecouterFichiersEntrants();
  }

  void _ecouterFichiersEntrants() {
    // Cas 1 : l'app était fermée et s'ouvre via un fichier .minsares
    ReceiveSharingIntent.instance.getInitialMedia().then((fichiers) {
      if (fichiers.isNotEmpty) {
        _traiterFichier(fichiers.first.path);
      }
    });

    // Cas 2 : l'app était déjà ouverte en arrière-plan
    ReceiveSharingIntent.instance.getMediaStream().listen((fichiers) {
      if (fichiers.isNotEmpty) {
        _traiterFichier(fichiers.first.path);
      }
    });
  }

  Future<void> _traiterFichier(String chemin) async {
    // On n'accepte que les .minsares
    if (!chemin.endsWith('.minsares')) return;

    try {
      final result = await _importService.importerFichier(chemin);
      if (mounted) _afficherSucces(result);
    } catch (e) {
      if (mounted) _afficherErreur(e.toString());
    }
  }

  void _afficherSucces(ImportResult result) {
    final dateStr =
        '${result.date.day}/${result.date.month}/${result.date.year}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Rapport importé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LigneDetail(Icons.location_on, 'Lieu', result.lieu),
            _LigneDetail(Icons.calendar_today, 'Date', dateStr),
            _LigneDetail(
              Icons.group,
              'Évangélisateurs',
              '${result.nbEvangelisateurs}',
            ),
            _LigneDetail(
              Icons.favorite,
              'Personnes touchées',
              '${result.nbPersonnesTouchees}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aller sur l'onglet Sorties pour voir le rapport importé
              setState(() => _idx = 1);
            },
            child: const Text('Voir la sortie'),
          ),
        ],
      ),
    );
  }

  void _afficherErreur(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur d\'import'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: const [DashboardScreen(), SortiesScreen(), StatsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_rounded),
            label: 'Sorties',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

class _LigneDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;
  const _LigneDetail(this.icon, this.label, this.valeur);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            valeur,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
