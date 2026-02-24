import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'ristourne.g.dart';

@HiveType(typeId: 2)
class Ristourne extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String agentId;

  @HiveField(2)
  String gestionnaireId;

  @HiveField(3)
  String operateur; // 'MTN', 'Moov', 'Celtiis'

  @HiveField(4)
  double montant;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String controleurId;

  @HiveField(7)
  String? observations;

  @HiveField(8)
  bool retiree;

  @HiveField(9)
  DateTime? dateRetrait;

  @HiveField(10)
  String? retireePar;

  @HiveField(11)
  String? entrepriseId;

  Ristourne({
    required this.id,
    required this.agentId,
    required this.gestionnaireId,
    required this.operateur,
    required this.montant,
    required this.date,
    required this.controleurId,
    this.observations,
    this.retiree = false,
    this.dateRetrait,
    this.retireePar,
    this.entrepriseId,
  });

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Color get couleurOperateur {
    switch (operateur) {
      case 'MTN':   return const Color(0xFFFFCC00);
      case 'Moov':  return const Color(0xFF0066CC);
      case 'Celtiis': return const Color(0xFFCC0000);
      default: return const Color(0xFF666666);
    }
  }
}
