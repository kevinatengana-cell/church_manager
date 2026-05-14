import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../models/sortie.dart';
import 'sortie_detail_screen.dart';
import 'nouvelle_sortie_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();

  Future<Map<String, dynamic>> _loadStats() async {
    final sorties = await _db.getSorties();
    final totalSorties = await _db.countSorties();
    final totalTouches = await _db.countPersonnesTouchees();
    final totalEvUniques = await _db.countEvangelisateursUniques();
    return {
      'sorties': totalSorties,
      'touches': totalTouches,
      'evUniques': totalEvUniques,
      'recent': sorties.take(3).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadStats(),
          builder: (ctx, snap) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (!snap.hasData)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _StatsRow(snap.data!),
                        const SizedBox(height: 28),
                        _SectionTitle('Dernières sorties'),
                        const SizedBox(height: 12),
                        ..._buildRecentSorties(
                            snap.data!['recent'] as List<Sortie>),
                      ]),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NouvellesSortieScreen()));
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle sortie'),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Évangélisation MINSARES',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.white)), // blanc sur fond bleu
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.blueDark
              ], // #163E8C → bleu foncé
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.church,
                  size: 80, color: AppTheme.primary.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentSorties(List<Sortie> sorties) {
    if (sorties.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Center(
            child: Column(children: [
              Icon(Icons.event_note, size: 40, color: AppTheme.textSecondary),
              SizedBox(height: 8),
              Text('Aucune sortie enregistrée',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ]),
          ),
        ),
      ];
    }
    return sorties
        .map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SortieCard(
                sortie: s,
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SortieDetailScreen(sortie: s)));
                  setState(() {});
                },
              ),
            ))
        .toList();
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary));
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsRow(this.data);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Sorties',
            value: '${data['sorties']}',
            icon: Icons.event,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Évangélistes',
            value: '${data['evUniques']}',
            icon: Icons.group,
            color: AppTheme.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Personnes touchées',
            value: '${data['touches']}',
            icon: Icons.favorite,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              maxLines: 2),
        ],
      ),
    );
  }
}

// ─── Sortie Card (shared widget) ──────────────────────────────────────────────

class _SortieCard extends StatelessWidget {
  final Sortie sortie;
  final VoidCallback onTap;
  const _SortieCard({required this.sortie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${sortie.date.day.toString().padLeft(2, '0')}/${sortie.date.month.toString().padLeft(2, '0')}/${sortie.date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.church, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sortie.lieu,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge('${sortie.evangelisateurs.length} év.', AppTheme.teal),
                const SizedBox(height: 4),
                _Badge('${sortie.personnesTouchees.length} touchées',
                    AppTheme.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
