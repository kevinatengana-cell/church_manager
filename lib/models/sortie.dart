class Sortie {
  final int? id;
  final DateTime date;
  final String lieu;
  final String? notes;
  final bool isImported;
  final String? senderName;
  List<Evangelisateur> evangelisateurs;
  List<PersonneTouchee> personnesTouchees;

  Sortie({
    this.id,
    required this.date,
    required this.lieu,
    this.notes,
    this.isImported = false,
    this.senderName,
    this.evangelisateurs = const [],
    this.personnesTouchees = const [],
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'lieu': lieu,
        'notes': notes,
        'is_imported': isImported ? 1 : 0,
        'sender_name': senderName,
      };

  factory Sortie.fromMap(Map<String, dynamic> map) => Sortie(
        id: map['id'],
        date: DateTime.parse(map['date']),
        lieu: map['lieu'],
        notes: map['notes'],
        isImported: (map['is_imported'] ?? 0) == 1,
        senderName: map['sender_name'],
      );
}

class Evangelisateur {
  final int? id;
  final String nom;
  final int sortieId;

  Evangelisateur({this.id, required this.nom, required this.sortieId});

  Map<String, dynamic> toMap() => {'nom': nom, 'sortie_id': sortieId};

  factory Evangelisateur.fromMap(Map<String, dynamic> map) => Evangelisateur(
        id: map['id'],
        nom: map['nom'],
        sortieId: map['sortie_id'],
      );
}

class PersonneTouchee {
  final int? id;
  final String nom;
  final String? contact;
  final int sortieId;

  PersonneTouchee(
      {this.id, required this.nom, this.contact, required this.sortieId});

  Map<String, dynamic> toMap() =>
      {'nom': nom, 'contact': contact, 'sortie_id': sortieId};

  factory PersonneTouchee.fromMap(Map<String, dynamic> map) => PersonneTouchee(
        id: map['id'],
        nom: map['nom'],
        contact: map['contact'],
        sortieId: map['sortie_id'],
      );
}
