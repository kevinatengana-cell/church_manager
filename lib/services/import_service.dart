import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import '../models/sortie.dart';
import '../services/database_service.dart';

class ImportService {
  static final ImportService _i = ImportService._();
  factory ImportService() => _i;
  ImportService._();

  static const String _secretKey = 'MINSARES2026SecretKey#Evang@Sec!';
  static const String _iv = 'MINSARES_IV_1234';

  // ─── Déchiffrement ────────────────────────────────────────────────────────

  String _dechiffrer(String base64Chiffre) {
    final key = enc.Key.fromUtf8(_secretKey);
    final iv = enc.IV.fromUtf8(_iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(base64Chiffre, iv: iv);
  }

  // ─── Import principal ─────────────────────────────────────────────────────

  /// Lit un fichier .minsares, le déchiffre, et l'insère en DB.
  /// Retourne un résumé de l'import pour affichage à l'utilisateur.
  Future<ImportResult> importerFichier(String cheminFichier) async {
    // 1. Lire le fichier
    final fichier = File(cheminFichier);
    if (!await fichier.exists()) {
      throw Exception('Fichier introuvable : $cheminFichier');
    }
    final contenuChiffre = await fichier.readAsString();

    // 2. Déchiffrer
    final String jsonBrut;
    try {
      jsonBrut = _dechiffrer(contenuChiffre);
    } catch (_) {
      throw Exception(
          'Ce fichier ne peut pas être lu. Il a peut-être été corrompu ou ne provient pas de l\'app MINSARES.');
    }

    // 3. Parser le JSON
    final Map<String, dynamic> data = jsonDecode(jsonBrut);

    // Vérification basique du format
    if (data['app'] != 'minsares' || data['sortie'] == null) {
      throw Exception('Format de fichier invalide.');
    }

    final Map<String, dynamic> sortieData = data['sortie'];

    // 4. Construire l'objet Sortie
    final sortie = Sortie(
      date: DateTime.parse(sortieData['date']),
      lieu: sortieData['lieu'] ?? '',
      notes: sortieData['notes'],
      isImported: true,
      senderName: data['sender_name'] as String?,
    );

    final evangelisateurs = (sortieData['evangelisateurs'] as List<dynamic>?)
            ?.map((e) => e['nom'] as String)
            .toList() ??
        [];

    final personnesTouchees =
        (sortieData['personnes_touchees'] as List<dynamic>?)
                ?.map((p) => {
                      'nom': p['nom'] as String,
                      'contact': p['contact'] as String? ?? '',
                    })
                .toList() ??
            [];

    // 5. Insérer en base de données
    final db = DatabaseService();
    final sortieId = await db.addSortie(sortie);
    await db.replaceEvangelisateurs(sortieId, evangelisateurs);
    await db.replacePersonnesTouchees(sortieId, personnesTouchees);

    return ImportResult(
      lieu: sortie.lieu,
      date: sortie.date,
      nbEvangelisateurs: evangelisateurs.length,
      nbPersonnesTouchees: personnesTouchees.length,
    );
  }
}

// ─── Résultat d'import (pour affichage) ──────────────────────────────────────

class ImportResult {
  final String lieu;
  final DateTime date;
  final int nbEvangelisateurs;
  final int nbPersonnesTouchees;

  ImportResult({
    required this.lieu,
    required this.date,
    required this.nbEvangelisateurs,
    required this.nbPersonnesTouchees,
  });
}
