import 'package:hive/hive.dart';

part 'entreprise_model.g.dart';

@HiveType(typeId: 4)
class EntrepriseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  double capitalDepart;

  @HiveField(3)
  String gestionnaireId;

  @HiveField(4)
  DateTime dateCreation;

  @HiveField(5)
  String? description;

  EntrepriseModel({
    required this.id,
    required this.nom,
    required this.capitalDepart,
    required this.gestionnaireId,
    required this.dateCreation,
    this.description,
  });

  String get capitalFormate {
    if (capitalDepart >= 1000000) {
      return '${(capitalDepart / 1000000).toStringAsFixed(1)} M FCFA';
    } else if (capitalDepart >= 1000) {
      return '${(capitalDepart / 1000).toStringAsFixed(0)} K FCFA';
    }
    return '${capitalDepart.toStringAsFixed(0)} FCFA';
  }
}
