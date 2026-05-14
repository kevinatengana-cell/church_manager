import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../models/sortie.dart';
import 'nouvelle_sortie_screen.dart';

class SortieDetailScreen extends StatefulWidget {
  final Sortie sortie;
  const SortieDetailScreen({Key? key, required this.sortie}) : super(key: key);
  @override
  State<SortieDetailScreen> createState() => _SortieDetailScreenState();
}

class _SortieDetailScreenState extends State<SortieDetailScreen> {
  final _db = DatabaseService();
  late Sortie _sortie;

  @override
  void initState() {
    super.initState();
    _sortie = widget.sortie;
  }

  Future<void> _reload() async {
    final s = await _db.getSortie(_sortie.id!);
    if (s != null && mounted) setState(() => _sortie = s);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Supprimer cette sortie ?'),
        content: const Text(
            'Tous les évangélisateurs et personnes touchées seront supprimés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteSortie(_sortie.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _sortie.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_sortie.lieu),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NouvellesSortieScreen(sortie: _sortie)));
              await _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.primary.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_sortie.lieu,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  if (_sortie.notes != null && _sortie.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_sortie.notes!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, height: 1.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary row
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    label: 'Évangélisateurs',
                    count: _sortie.evangelisateurs.length,
                    color: AppTheme.teal,
                    icon: Icons.group_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryBox(
                    label: 'Personnes touchées',
                    count: _sortie.personnesTouchees.length,
                    color: AppTheme.secondary,
                    icon: Icons.favorite_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Evangelisateurs list
            _SectionHeader(
                'Évangélisateurs', AppTheme.teal, Icons.group_rounded),
            const SizedBox(height: 10),
            if (_sortie.evangelisateurs.isEmpty)
              _EmptyBox('Aucun évangélisateur enregistré')
            else
              ..._sortie.evangelisateurs
                  .map((e) => _PersonTile(e.nom, null, AppTheme.teal))
                  .toList(),

            const SizedBox(height: 24),

            // Personnes touchées list
            _SectionHeader(
                'Personnes touchées', AppTheme.secondary, Icons.favorite_rounded),
            const SizedBox(height: 10),
            if (_sortie.personnesTouchees.isEmpty)
              _EmptyBox('Aucune personne touchée enregistrée')
            else
              ..._sortie.personnesTouchees
                  .map((p) => _PersonTile(p.nom, p.contact, AppTheme.secondary))
                  .toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  const _SectionHeader(this.title, this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryBox(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final String nom;
  final String? contact;
  final Color color;
  const _PersonTile(this.nom, this.contact, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Text(nom[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              if (contact != null && contact!.isNotEmpty)
                Text(contact!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child:
          Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
    );
  }
}
