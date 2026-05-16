import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = DatabaseService();

  Future<Map<String, dynamic>> _load() async {
    final participation = await _db.getParticipationStats();
    final touchesParSortie = await _db.getTouchesParSortie();
    final totalSorties = await _db.countSorties();
    final totalTouches = await _db.countPersonnesTouchees();
    final totalEvUniq = await _db.countEvangelisateursUniques();
    final statsParLieu = await _db.getStatsByLieu();
    final lieux = await _db.getLieux();
    final evangelistes = await _db.getEvangelistesList();
    final allLieuxEvol = await _db.getEvolutionAllLieux();
    return {
      'participation': participation,
      'touchesParSortie': touchesParSortie,
      'statsParLieu': statsParLieu,
      'totalSorties': totalSorties,
      'totalTouches': totalTouches,
      'totalEvUniq': totalEvUniq,
      'lieux': lieux,
      'evangelistes': evangelistes,
      'allLieuxEvol': allLieuxEvol,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final participation =
              data['participation'] as List<Map<String, dynamic>>;
          final touchesParSortie =
              data['touchesParSortie'] as List<Map<String, dynamic>>;
          final statsParLieu =
              data['statsParLieu'] as List<Map<String, dynamic>>;
          final lieux = data['lieux'] as List<String>;
          final evangelistes = data['evangelistes'] as List<String>;
          final allLieuxEvol = data['allLieuxEvol'] as Map<String, List<Map<String, dynamic>>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Global summary ──────────────────────────────────────
                _GlobalSummary(
                  sorties: data['totalSorties'] as int,
                  touches: data['totalTouches'] as int,
                  evUniq: data['totalEvUniq'] as int,
                ),
                const SizedBox(height: 28),

                // ── Évolution globale (Toutes entrées) ────────────────────
                _SectionTitle(
                    'Personnes touchées par sortie', AppTheme.secondary),
                const SizedBox(height: 12),
                if (touchesParSortie.isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else
                  _TouchesChart(touchesParSortie),

                const SizedBox(height: 28),

                // ── Évolution comparée des Lieux (Multi-courbes) ─────────────
                _SectionTitle('Comparatif des Lieux', AppTheme.teal),
                const SizedBox(height: 12),
                if (allLieuxEvol.keys.where((k) => k != '__dates__').isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else
                  _MultiLieuxChart(allLieuxEvol),

                const SizedBox(height: 28),

                // ── Classement participation (Assiduité globale) ─────────────
                _SectionTitle('Assiduité Globale', AppTheme.amber),
                const SizedBox(height: 12),
                if (participation.isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else
                  _ParticipationList(participation, data['totalSorties'] as int),

                const SizedBox(height: 28),

                // ── Assiduité par Zone ───────────────────────────────────────
                _SectionTitle('Assiduité par Zone', AppTheme.amber),
                const SizedBox(height: 12),
                _AssiduiteParLieu(lieux),

                const SizedBox(height: 28),

                // ── Stats par lieu (Total Bar Chart) ─────────────────────────
                _SectionTitle('Total par lieu d\'évangélisation', AppTheme.primary),
                const SizedBox(height: 12),
                if (statsParLieu.isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else ...[
                  _LieuBarChart(statsParLieu),
                  const SizedBox(height: 16),
                  _LieuStatsList(statsParLieu),
                ],

                const SizedBox(height: 28),

                // ── Évolution par Lieu Individuel ─────────────────────────────
                _SectionTitle('Évolution par Lieu (Détail)', AppTheme.primary),
                const SizedBox(height: 12),
                _EvolutionParLieu(lieux),

                const SizedBox(height: 28),

                // ── Évolution par Évangéliste ──────────────────────────────────
                _SectionTitle('Évolution par Évangéliste', AppTheme.amber),
                const SizedBox(height: 12),
                _EvolutionParEvangeliste(evangelistes),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Global Summary ──────────────────────────────────────────────────────────

class _GlobalSummary extends StatelessWidget {
  final int sorties, touches, evUniq;
  const _GlobalSummary(
      {required this.sorties, required this.touches, required this.evUniq});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.25),
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
          const Text('Vue d\'ensemble',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigStat('$sorties', 'Sorties', Icons.event),
              _BigStat('$evUniq', 'Évangélistes\nuniques', Icons.group),
              _BigStat('$touches', 'Personnes\ntouchées', Icons.favorite),
            ],
          ),
          if (sorties > 0) ...[
            const Divider(height: 24, color: AppTheme.border),
            Text(
              'Moyenne : ${(touches / sorties).toStringAsFixed(1)} personnes touchées / sortie',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _BigStat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(height: 6),
      Text(value,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}

// ─── Touches chart ──────────────────────────────────────────────────────────

class _TouchesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TouchesChart(this.data);

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['touches'] as int).toDouble());
    }).toList();

    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) + 2;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  final dateStr = data[idx]['date'] as String;
                  final d = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${d.day}/${d.month}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.secondary,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.secondary.withOpacity(0.1),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.secondary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.card,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Participation list (Assiduité) ──────────────────────────────────────────

class _ParticipationList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int totalSortiesGlobals;
  const _ParticipationList(this.data, this.totalSortiesGlobals);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final nom = row['nom'] as String;
        final total = row['total'] as int;
        final assiduite = totalSortiesGlobals > 0 ? (total / totalSortiesGlobals) * 100 : 0.0;
        final ratio = totalSortiesGlobals > 0 ? total / totalSortiesGlobals : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: i == 0
                      ? AppTheme.amber.withOpacity(0.2)
                      : AppTheme.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: i == 0 ? AppTheme.amber : AppTheme.teal,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            i == 0 ? AppTheme.amber : AppTheme.teal),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${assiduite.toStringAsFixed(1)} %',
                      style: TextStyle(
                          color: i == 0 ? AppTheme.amber : AppTheme.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('$total / $totalSortiesGlobals sorties',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Lieu stats list ─────────────────────────────────────────────────────────

class _LieuStatsList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _LieuStatsList(this.data);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.map((row) {
        final lieu = row['lieu'] as String;
        final totalSorties = row['total_sorties'] as int;
        final touches = row['touches'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: AppTheme.primary, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lieu,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$totalSorties sortie${totalSorties > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$touches',
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Text('touchés',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 4,
            height: 18,
            color: color,
            margin: const EdgeInsets.only(right: 10)),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
      ]);
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
          child: Text(text,
              style: const TextStyle(color: AppTheme.textSecondary))),
    );
  }
}

// ─── Évolution par Lieu ──────────────────────────────────────────────────────

class _EvolutionParLieu extends StatefulWidget {
  final List<String> lieux;
  const _EvolutionParLieu(this.lieux);
  @override
  State<_EvolutionParLieu> createState() => _EvolutionParLieuState();
}

class _EvolutionParLieuState extends State<_EvolutionParLieu> {
  String? _selected;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lieux.isNotEmpty) {
      _selected = widget.lieux.first;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    _data = await DatabaseService().getEvolutionParLieu(_selected!);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lieux.isEmpty) return const _EmptyState('Aucun lieu');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: widget.lieux
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selected = v);
                  _loadData();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_data.isEmpty) const _EmptyState('Aucune donnée')
        else _TouchesChart(_data),
      ],
    );
  }
}

// ─── Évolution par Évangéliste ───────────────────────────────────────────────

class _EvolutionParEvangeliste extends StatefulWidget {
  final List<String> evangelistes;
  const _EvolutionParEvangeliste(this.evangelistes);
  @override
  State<_EvolutionParEvangeliste> createState() => _EvolutionParEvangelisteState();
}

class _EvolutionParEvangelisteState extends State<_EvolutionParEvangeliste> {
  String? _selected;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.evangelistes.isNotEmpty) {
      _selected = widget.evangelistes.first;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    _data = await DatabaseService().getEvolutionParEvangeliste(_selected!);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evangelistes.isEmpty) return const _EmptyState('Aucun évangéliste');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: widget.evangelistes
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selected = v);
                  _loadData();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_data.isEmpty) const _EmptyState('Aucune donnée')
        else _TouchesChart(_data),
      ],
    );
  }
}

// ─── Lieu Bar Chart (Total) ──────────────────────────────────────────────────

class _LieuBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> statsParLieu;
  const _LieuBarChart(this.statsParLieu);

  @override
  Widget build(BuildContext context) {
    // Only take top 5 or all if less to avoid crowding
    final data = statsParLieu.take(5).toList();
    if (data.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var r in data) {
      if ((r['touches'] as int) > maxY) maxY = (r['touches'] as int).toDouble();
    }
    maxY += 5;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  String title = data[idx]['lieu'] as String;
                  if (title.length > 6) title = '${title.substring(0, 5)}.';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(title, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final idx = e.key;
            final val = (e.value['touches'] as int).toDouble();
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: AppTheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Multi-Lieux Chart ───────────────────────────────────────────────────────

class _MultiLieuxChart extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> allLieuxEvol;
  const _MultiLieuxChart(this.allLieuxEvol);

  @override
  Widget build(BuildContext context) {
    final datesInfo = allLieuxEvol['__dates__'] ?? [];
    final allDates = datesInfo.map((e) => e['date'] as String).toList();
    
    final lieuxKeys = allLieuxEvol.keys.where((k) => k != '__dates__').toList();
    
    double maxY = 0;
    for (var k in lieuxKeys) {
      for (var pt in allLieuxEvol[k]!) {
        final y = (pt['touches'] as int).toDouble();
        if (y > maxY) maxY = y;
      }
    }
    maxY += 2;

    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.amber,
      AppTheme.teal,
      Colors.deepPurpleAccent,
      Colors.pinkAccent,
      Colors.lightBlue,
      Colors.lightGreen,
    ];

    final lineBars = <LineChartBarData>[];
    int colorIdx = 0;

    for (var k in lieuxKeys) {
      final color = colors[colorIdx % colors.length];
      colorIdx++;

      final spots = allLieuxEvol[k]!.map((pt) {
        return FlSpot((pt['x'] as int).toDouble(), (pt['touches'] as int).toDouble());
      }).toList();

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1,
                strokeColor: AppTheme.card,
              ),
            ),
          )
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (allDates.length - 1).toDouble().clamp(0, double.infinity),
              minY: 0,
              maxY: maxY,
              lineBarsData: lineBars,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= allDates.length) return const SizedBox();
                      final d = DateTime.parse(allDates[idx]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${d.day}/${d.month}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: lieuxKeys.asMap().entries.map((e) {
            final idx = e.key;
            final nom = e.value;
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(nom, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Assiduité par Lieu ──────────────────────────────────────────────────────

class _AssiduiteParLieu extends StatefulWidget {
  final List<String> lieux;
  const _AssiduiteParLieu(this.lieux);
  @override
  State<_AssiduiteParLieu> createState() => _AssiduiteParLieuState();
}

class _AssiduiteParLieuState extends State<_AssiduiteParLieu> {
  String? _selected;
  List<Map<String, dynamic>> _participation = [];
  int _totalSortiesLieu = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lieux.isNotEmpty) {
      _selected = widget.lieux.first;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    final data = await DatabaseService().getAssiduiteParLieu(_selected!);
    setState(() {
      _participation = data['participation'] as List<Map<String, dynamic>>;
      _totalSortiesLieu = data['totalSorties'] as int;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lieux.isEmpty) return const _EmptyState('Aucune zone disponible');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: widget.lieux
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selected = v);
                  _loadData();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_participation.isEmpty) const _EmptyState('Aucun participant pour cette zone')
        else _ParticipationList(_participation, _totalSortiesLieu),
      ],
    );
  }
}
