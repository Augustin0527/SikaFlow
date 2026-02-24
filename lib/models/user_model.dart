import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String prenom;

  @HiveField(3)
  String telephone;

  @HiveField(4)
  String motDePasse;

  @HiveField(5)
  String role; // 'gestionnaire', 'agent', 'controleur'

  @HiveField(6)
  String? gestionnaireId;

  @HiveField(7)
  DateTime dateCreation;

  @HiveField(8)
  bool actif;

  @HiveField(9)
  String? email;

  @HiveField(10)
  String? entrepriseId;

  @HiveField(11)
  bool motDePasseProvisoire; // true = doit changer son mdp à la 1ère connexion

  @HiveField(12)
  String? controleurAssigneId; // Pour les agents : ID du contrôleur assigné

  @HiveField(13)
  List<String> agentsAssignesIds; // Pour les contrôleurs : liste d'agents assignés

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.motDePasse,
    required this.role,
    this.gestionnaireId,
    required this.dateCreation,
    this.actif = true,
    this.email,
    this.entrepriseId,
    this.motDePasseProvisoire = false,
    this.controleurAssigneId,
    List<String>? agentsAssignesIds,
  }) : agentsAssignesIds = agentsAssignesIds ?? [];

  String get nomComplet => '$prenom $nom';

  String get identifiantConnexion => telephone.isNotEmpty ? telephone : (email ?? '');

  bool get estGestionnaire => role == 'gestionnaire';
  bool get estAgent => role == 'agent';
  bool get estControleur => role == 'controleur';

  String get roleLibelle {
    switch (role) {
      case 'gestionnaire': return 'Gestionnaire';
      case 'agent': return 'Agent';
      case 'controleur': return 'Contrôleur';
      default: return role;
    }
  }
}
