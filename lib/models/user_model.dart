import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String telephone;
  final String? email;
  final String role; // super_admin | gestionnaire | agent | controleur
  final String? entrepriseId;
  final String? standId; // stand actuel de l'agent
  final DateTime dateCreation;
  final DateTime? dateAffectationStand;
  final bool motDePasseProvisoire;
  final bool actif;
  // Permissions spéciales contrôleur (définies par le gestionnaire)
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.telephone,
    this.email,
    required this.role,
    this.entrepriseId,
    this.standId,
    required this.dateCreation,
    this.dateAffectationStand,
    required this.motDePasseProvisoire,
    required this.actif,
    this.permissions = const [],
  });

  String get nomComplet => '$prenom $nom';

  bool get estSuperAdmin => role == 'super_admin';
  bool get estGestionnaire => role == 'gestionnaire';
  bool get estAgent => role == 'agent';
  bool get estControleur => role == 'controleur';

  bool hasPermission(String permission) {
    if (estGestionnaire) return true;
    return permissions.contains(permission);
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      prenom: (data['prenom'] ?? '') as String,
      nom: (data['nom'] ?? '') as String,
      telephone: (data['telephone'] ?? '') as String,
      email: data['email'] as String?,
      role: (data['role'] ?? 'agent') as String,
      entrepriseId: data['entreprise_id'] as String?,
      standId: data['stand_id'] as String?,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateAffectationStand: (data['date_affectation_stand'] as Timestamp?)?.toDate(),
      motDePasseProvisoire: (data['mot_de_passe_provisoire'] ?? false) as bool,
      actif: (data['actif'] ?? true) as bool,
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'prenom': prenom,
    'nom': nom,
    'telephone': telephone,
    'email': email,
    'role': role,
    'entreprise_id': entrepriseId,
    'stand_id': standId,
    'date_creation': Timestamp.fromDate(dateCreation),
    'date_affectation_stand': dateAffectationStand != null
        ? Timestamp.fromDate(dateAffectationStand!)
        : null,
    'mot_de_passe_provisoire': motDePasseProvisoire,
    'actif': actif,
    'permissions': permissions,
  };
}

// ─── Permissions disponibles pour les contrôleurs ───────────────────────────
class Permissions {
  static const String gererAgents          = 'gerer_agents';
  static const String gererStands          = 'gerer_stands';
  static const String approuverReequilibrage = 'approuver_reequilibrage';
  static const String modifierOperations   = 'modifier_operations';
  static const String voirRapports         = 'voir_rapports';
  static const String initialiserSoldes    = 'initialiser_soldes';
  static const String voirTousLesStands    = 'voir_tous_stands';

  static const List<String> toutes = [
    gererAgents,
    gererStands,
    approuverReequilibrage,
    modifierOperations,
    voirRapports,
    initialiserSoldes,
    voirTousLesStands,
  ];

  static String label(String permission) {
    switch (permission) {
      case gererAgents:           return 'Gérer les agents';
      case gererStands:           return 'Gérer les stands';
      case approuverReequilibrage:return 'Approuver rééquilibrages';
      case modifierOperations:    return 'Modifier les opérations';
      case voirRapports:          return 'Voir les rapports financiers';
      case initialiserSoldes:     return 'Initialiser les soldes';
      case voirTousLesStands:     return 'Voir tous les stands';
      default:                    return permission;
    }
  }
}
