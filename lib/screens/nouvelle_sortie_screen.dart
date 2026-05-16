import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../models/sortie.dart';

class NouvellesSortieScreen extends StatefulWidget {
  final Sortie? sortie; // null = création, non-null = édition
  const NouvellesSortieScreen({Key? key, this.sortie}) : super(key: key);
  @override
  State<NouvellesSortieScreen> createState() => _NouvellesSortieScreenState();
}

class _NouvellesSortieScreenState extends State<NouvellesSortieScreen> {
  final _db = DatabaseService();
  final _lieuCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  // Évangélistes : liste de contrôleurs de texte
  final List<TextEditingController> _evCtrlList = [];

  // Personnes touchées : liste de {nom, contact}
  final List<Map<String, TextEditingController>> _ptList = [];

  bool get _isEdit => widget.sortie != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.sortie!;
      _lieuCtrl.text = s.lieu;
      _notesCtrl.text = s.notes ?? '';
      _date = s.date;
      for (final e in s.evangelisateurs) {
        _evCtrlList.add(TextEditingController(text: e.nom));
      }
      for (final p in s.personnesTouchees) {
        _ptList.add({
          'nom': TextEditingController(text: p.nom),
          'contact': TextEditingController(text: p.contact ?? ''),
        });
      }
    }
  }

  @override
  void dispose() {
    _lieuCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _evCtrlList) c.dispose();
    for (final m in _ptList) {
      m['nom']!.dispose();
      m['contact']!.dispose();
    }
    super.dispose();
  }

  void _addEv() => setState(() => _evCtrlList.add(TextEditingController()));

  void _removeEv(int i) {
    _evCtrlList[i].dispose();
    setState(() => _evCtrlList.removeAt(i));
  }

  void _addPt() => setState(() => _ptList.add({
        'nom': TextEditingController(),
        'contact': TextEditingController(),
      }));

  void _removePt(int i) {
    _ptList[i]['nom']!.dispose();
    _ptList[i]['contact']!.dispose();
    setState(() => _ptList.removeAt(i));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_lieuCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le lieu est obligatoire')));
      return;
    }

    setState(() => _saving = true);

    final noms = _evCtrlList.map((c) => c.text.trim()).toList();
    final ptData = _ptList
        .map((m) => {
              'nom': m['nom']!.text.trim(),
              'contact': m['contact']!.text.trim(),
            })
        .toList();

    if (_isEdit) {
      await _db.updateSortie(Sortie(
        id: widget.sortie!.id,
        date: _date,
        lieu: _lieuCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      await _db.replaceEvangelisateurs(widget.sortie!.id!, noms);
      await _db.replacePersonnesTouchees(widget.sortie!.id!, ptData);
    } else {
      final sortieId = await _db.addSortie(Sortie(
        date: _date,
        lieu: _lieuCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      await _db.replaceEvangelisateurs(sortieId, noms);
      await _db.replacePersonnesTouchees(sortieId, ptData);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la sortie' : 'Nouvelle sortie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Infos générales ───────────────────────────────────────────
            _SectionLabel('Informations générales'),
            const SizedBox(height: 12),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15)),
                  const Spacer(),
                  const Icon(Icons.edit,
                      size: 16, color: AppTheme.textSecondary),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _lieuCtrl,
              decoration: const InputDecoration(
                  labelText: 'Lieu de la sortie *',
                  prefixIcon: Icon(Icons.location_on_rounded)),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.notes_rounded)),
              maxLines: 3,
            ),

            const SizedBox(height: 28),

            // ── Évangélistes ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Évangélistes (${_evCtrlList.length})'),
                TextButton.icon(
                  onPressed: _addEv,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.teal),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_evCtrlList.isEmpty)
              _HintBox('Aucun évangélisateur ajouté', AppTheme.teal),

            ...List.generate(_evCtrlList.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.teal.withOpacity(0.15),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppTheme.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _evCtrlList[i],
                      decoration: InputDecoration(
                        hintText: 'Nom de l\'évangélisateur',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.teal.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.teal.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _removeEv(i),
                  ),
                ]),
              );
            }),

            const SizedBox(height: 24),

            // ── Personnes touchées ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Personnes touchées (${_ptList.length})'),
                TextButton.icon(
                  onPressed: _addPt,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppTheme.secondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_ptList.isEmpty)
              _HintBox('Aucune personne touchée ajoutée', AppTheme.secondary),

            ...List.generate(_ptList.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.secondary.withOpacity(0.15),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(children: [
                        TextField(
                          controller: _ptList[i]['nom'],
                          decoration: InputDecoration(
                            hintText: 'Nom de la personne',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        AppTheme.secondary.withOpacity(0.4))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        AppTheme.secondary.withOpacity(0.3))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _ptList[i]['contact'],
                          decoration: InputDecoration(
                            hintText: 'Contact / téléphone (optionnel)',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        AppTheme.secondary.withOpacity(0.4))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        AppTheme.secondary.withOpacity(0.3))),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () => _removePt(i),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // ── Bouton sauvegarder ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label:
                    Text(_isEdit ? 'Mettre à jour' : 'Enregistrer la sortie'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary));
}

class _HintBox extends StatelessWidget {
  final String text;
  final Color color;
  const _HintBox(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.2), style: BorderStyle.solid),
      ),
      child: Text(text,
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 13)),
    );
  }
}
