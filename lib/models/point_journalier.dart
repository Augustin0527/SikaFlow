import 'package:hive/hive.dart';

part 'point_journalier.g.dart';

@HiveType(typeId: 1)
class PointJournalier extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String agentId;

  @HiveField(2)
  String gestionnaireId;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  double montantEspeces;

  @HiveField(5)
  double soldeMTN;

  @HiveField(6)
  double soldeMoov;

  @HiveField(7)
  double soldeCeltiis;

  @HiveField(8)
  String? observations;

  @HiveField(9)
  bool valide;

  @HiveField(10)
  String? validateurId;

  @HiveField(11)
  DateTime? dateValidation;

  @HiveField(12)
  String? entrepriseId;

  PointJournalier({
    required this.id,
    required this.agentId,
    required this.gestionnaireId,
    required this.date,
    required this.montantEspeces,
    required this.soldeMTN,
    required this.soldeMoov,
    required this.soldeCeltiis,
    this.observations,
    this.valide = false,
    this.validateurId,
    this.dateValidation,
    this.entrepriseId,
  });

  double get totalSIM => soldeMTN + soldeMoov + soldeCeltiis;
  double get totalGeneral => montantEspeces + totalSIM;

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
