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
    return {
      'participation': participation,
      'touchesParSortie': touchesParSortie,
      'totalSorties': totalSorties,
      'totalTouches': totalTouches,
      'totalEvUniq': totalEvUniq,
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

                // ── Évolution des personnes touchées ────────────────────
                _SectionTitle('Personnes touchées par sortie',
                    AppTheme.secondary),
                const SizedBox(height: 12),
                if (touchesParSortie.isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else
                  _TouchesChart(touchesParSortie),

                const SizedBox(height: 28),

                // ── Classement participation ─────────────────────────────
                _SectionTitle('Classement des évangélisateurs',
                    AppTheme.teal),
                const SizedBox(height: 12),
                if (participation.isEmpty)
                  _EmptyState('Aucune donnée disponible')
                else
                  _ParticipationList(participation),

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
              _BigStat('$evUniq', 'Évangélisateurs\nuniques', Icons.group),
              _BigStat('$touches', 'Personnes\ntouchées', Icons.favorite),
            ],
          ),
          if (sorties > 0) ...[
            const Divider(height: 24, color: AppTheme.border),
            Text(
              'Moyenne : ${(touches / sorties).toStringAsFixed(1)} personnes touchées / sortie',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
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
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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

    final maxY =
        spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) + 2;

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

// ─── Participation list ──────────────────────────────────────────────────────

class _ParticipationList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ParticipationList(this.data);

  @override
  Widget build(BuildContext context) {
    final maxVal =
        (data.first['total'] as int).toDouble();
    return Column(
      children: data.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final nom = row['nom'] as String;
        final total = row['total'] as int;
        final ratio = maxVal > 0 ? total / maxVal : 0.0;

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
              Text('$total sortie${total > 1 ? 's' : ''}',
                  style: TextStyle(
                      color: i == 0 ? AppTheme.amber : AppTheme.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
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
        Container(width: 4, height: 18, color: color,
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
      child:
          Center(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary))),
    );
  }
}
