import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanAbonnement {
  essai('essai_gratuit', 'Essai Gratuit', 0, 2, 30, 'Découvrez SikaFlow', 0xFFFFCC00),
  starter('starter', 'Starter', 5000, 5, 30, 'Jusqu\'à 5 agents', 0xFF4CAF50),
  business('business', 'Business', 15000, 20, 30, 'Jusqu\'à 20 agents', 0xFF2196F3),
  premium('premium', 'Premium', 35000, -1, 30, 'Agents illimités', 0xFF9C27B0);

  const PlanAbonnement(this.code, this.nom, this.prix, this.maxAgents,
      this.dureeJours, this.description, this.couleurHex);

  final String code;
  final String nom;
  final int prix;
  final int maxAgents;
  final int dureeJours;
  final String description;
  final int couleurHex;

  String get prixFormate => prix == 0 ? 'Gratuit' : '${prix.toString()} FCFA/mois';
  String get maxAgentsLabel => maxAgents == -1 ? 'Illimité' : '$maxAgents agents max';

  static PlanAbonnement fromCode(String code) =>
      PlanAbonnement.values.firstWhere((p) => p.code == code,
          orElse: () => PlanAbonnement.essai);
}

enum StatutAbonnement {
  actif('actif', 'Actif'),
  expire('expire', 'Expiré'),
  suspendu('suspendu', 'Suspendu'),
  annule('annule', 'Annulé');

  const StatutAbonnement(this.code, this.label);
  final String code;
  final String label;

  static StatutAbonnement fromCode(String code) =>
      StatutAbonnement.values.firstWhere((s) => s.code == code,
          orElse: () => StatutAbonnement.expire);
}

class AbonnementModel {
  final String id;
  final String entrepriseId;
  final String gestionnaireId;
  final PlanAbonnement plan;
  final StatutAbonnement statut;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montantPaye;
  final DateTime dateCreation;

  const AbonnementModel({
    required this.id,
    required this.entrepriseId,
    required this.gestionnaireId,
    required this.plan,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
    required this.montantPaye,
    required this.dateCreation,
  });

  bool get estActif => statut == StatutAbonnement.actif && dateFin.isAfter(DateTime.now());
  bool get estExpire => dateFin.isBefore(DateTime.now());
  int get joursRestants => dateFin.difference(DateTime.now()).inDays;

  factory AbonnementModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AbonnementModel(
      id: id,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      gestionnaireId: (data['gestionnaire_id'] ?? '') as String,
      plan: PlanAbonnement.fromCode((data['plan'] ?? 'essai_gratuit') as String),
      statut: StatutAbonnement.fromCode((data['statut'] ?? 'actif') as String),
      dateDebut: (data['date_debut'] as Timestamp).toDate(),
      dateFin: (data['date_fin'] as Timestamp).toDate(),
      montantPaye: ((data['montant_paye'] ?? 0) as num).toDouble(),
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
