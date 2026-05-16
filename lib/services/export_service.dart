import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sortie.dart';
import '../services/database_service.dart';

class ExportService {
  static final ExportService _i = ExportService._();
  factory ExportService() => _i;
  ExportService._();

  // Clé AES-256 partagée entre tous les appareils de l'app
  // 32 caractères exactement
  static const String _secretKey = 'MINSARES2026SecretKey#Evang@Sec!';
  static const String _iv = 'MINSARES_IV_1234'; // 16 caractères

  // ─── Chiffrement ──────────────────────────────────────────────────────────

  String _chiffrer(String texte) {
    final key = enc.Key.fromUtf8(_secretKey);
    final iv = enc.IV.fromUtf8(_iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.encrypt(texte, iv: iv).base64;
  }

  // ─── Sérialisation d'une Sortie en JSON ───────────────────────────────────

  Future<Map<String, dynamic>> _sortieToJson(Sortie sortie) async {
    final ownerName = await DatabaseService().getOwnerName();
    return {
      'version': '1.0',
      'app': 'minsares',
      'exported_at': DateTime.now().toIso8601String(),
      'sender_name': ownerName ?? 'Un évangéliste',
      'sortie': {
        'date': sortie.date.toIso8601String(),
        'lieu': sortie.lieu,
        'notes': sortie.notes,
        'evangelisateurs':
            sortie.evangelisateurs.map((e) => {'nom': e.nom}).toList(),
        'personnes_touchees': sortie.personnesTouchees
            .map((p) => {'nom': p.nom, 'contact': p.contact})
            .toList(),
      },
    };
  }

  // ─── Export principal ────────────────────────────────────────────────────

  Future<void> exporterSortie(Sortie sortie) async {
    // 1. Sérialiser
    final mapData = await _sortieToJson(sortie);
    final json = jsonEncode(mapData);

    // 2. Chiffrer
    final contenuChiffre = _chiffrer(json);

    // 3. Créer le fichier temporaire
    final dir = await getTemporaryDirectory();
    final nomFichier = 'sortie_${sortie.lieu.replaceAll(' ', '_')}'
        '_${sortie.date.day}-${sortie.date.month}-${sortie.date.year}'
        '.minsares';
    final fichier = File('${dir.path}/$nomFichier');
    await fichier.writeAsString(contenuChiffre);

    // 4. Partager via le menu natif (WhatsApp, Telegram, Email…)
    await Share.shareXFiles(
      [XFile(fichier.path)],
      subject: 'Rapport sortie – ${sortie.lieu}',
      text: 'Rapport d\'évangélisation MINSARES\n'
          'Lieu : ${sortie.lieu}\n'
          'Date : ${sortie.date.day}/${sortie.date.month}/${sortie.date.year}\n'
          'Ouvre ce fichier avec l\'app MINSARES.',
    );
  }
}
