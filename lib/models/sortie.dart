class Sortie {
  final int? id;
  final DateTime date;
  final String lieu;
  final String? notes;
  List<Evangelisateur> evangelisateurs;
  List<PersonneTouchee> personnesTouchees;

  Sortie({
    this.id,
    required this.date,
    required this.lieu,
    this.notes,
    this.evangelisateurs = const [],
    this.personnesTouchees = const [],
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'lieu': lieu,
        'notes': notes,
      };

  factory Sortie.fromMap(Map<String, dynamic> map) => Sortie(
        id: map['id'],
        date: DateTime.parse(map['date']),
        lieu: map['lieu'],
        notes: map['notes'],
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
