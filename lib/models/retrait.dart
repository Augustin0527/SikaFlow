import 'package:hive/hive.dart';

part 'retrait.g.dart';

@HiveType(typeId: 3)
class Retrait extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String gestionnaireId;

  @HiveField(2)
  String agentId;

  @HiveField(3)
  String type; // 'especes', 'ristourne_mtn', 'ristourne_moov', 'ristourne_celtiis'

  @HiveField(4)
  double montant;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? motif;

  @HiveField(7)
  String? ristourneId;

  @HiveField(8)
  String? entrepriseId;

  Retrait({
    required this.id,
    required this.gestionnaireId,
    required this.agentId,
    required this.type,
    required this.montant,
    required this.date,
    this.motif,
    this.ristourneId,
    this.entrepriseId,
  });

  String get typeLibelle {
    switch (type) {
      case 'especes': return 'Espèces';
      case 'ristourne_mtn': return 'Ristourne MTN';
      case 'ristourne_moov': return 'Ristourne Moov';
      case 'ristourne_celtiis': return 'Ristourne Celtiis';
      default: return type;
    }
  }

  bool get estRistourne => type.startsWith('ristourne_');

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
