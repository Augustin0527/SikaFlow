import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TARIFICATION PAR NOMBRE DE STANDS
// ─────────────────────────────────────────────────────────────────────────────
//
//  Mensuel                     Annuel (réduction 20%)
//  1 stand   →  3 000 F/mois   1 stand   →  28 800 F/an  (soit 2 400 F/mois)
//  2–3 stands→  6 000 F/mois   2–3 stands→  57 600 F/an  (soit 4 800 F/mois)
//  4–6 stands→ 12 000 F/mois   4–6 stands→ 115 200 F/an  (soit 9 600 F/mois)
//  7–10 stands→20 000 F/mois   7–10 stands→192 000 F/an  (soit 16 000 F/mois)
//  11+ stands → 30 000 F/mois  11+ stands → 288 000 F/an  (soit 24 000 F/mois)
//
//  Essai gratuit : 30 jours – 1 stand inclus
// ─────────────────────────────────────────────────────────────────────────────

enum PeriodeAbonnement {
  mensuel('mensuel', 'Mensuel', 1, 0.0),
  annuel('annuel', 'Annuel', 12, 0.20);  // 20% de réduction

  const PeriodeAbonnement(this.code, this.label, this.mois, this.remise);
  final String code;
  final String label;
  final int mois;
  final double remise;  // 0.0 = pas de remise, 0.20 = 20%

  static PeriodeAbonnement fromCode(String code) =>
      PeriodeAbonnement.values.firstWhere((p) => p.code == code,
          orElse: () => PeriodeAbonnement.mensuel);
}

class PlanStands {
  final String code;
  final String label;
  final int minStands;
  final int maxStands;   // -1 = illimité
  final int prixMensuel; // FCFA / mois
  final String description;
  final int couleurHex;

  const PlanStands({
    required this.code,
    required this.label,
    required this.minStands,
    required this.maxStands,
    required this.prixMensuel,
    required this.description,
    required this.couleurHex,
  });

  /// Prix mensuel après remise annuelle (arrondi à l'unité)
  int prixMensuelAvecPeriode(PeriodeAbonnement periode) {
    if (periode == PeriodeAbonnement.annuel) {
      return (prixMensuel * (1 - periode.remise)).round();
    }
    return prixMensuel;
  }

  /// Total à payer selon la période
  int totalPeriode(PeriodeAbonnement periode) =>
      prixMensuelAvecPeriode(periode) * periode.mois;

  /// Économie en FCFA par rapport au mensuel sur 12 mois
  int economieAnnuelle() =>
      prixMensuel * 12 - totalPeriode(PeriodeAbonnement.annuel);

  String get maxStandsLabel =>
      maxStands == -1 ? 'Stands illimités' : '$maxStands stand${maxStands > 1 ? "s" : ""} max';

  static const List<PlanStands> tous = [
    PlanStands(
      code: 'solo',
      label: 'Solo',
      minStands: 1,
      maxStands: 1,
      prixMensuel: 3000,
      description: '1 stand · Idéal pour démarrer',
      couleurHex: 0xFF4CAF50,
    ),
    PlanStands(
      code: 'duo',
      label: 'Duo',
      minStands: 2,
      maxStands: 3,
      prixMensuel: 6000,
      description: '2 à 3 stands · Pour une petite agence',
      couleurHex: 0xFF2196F3,
    ),
    PlanStands(
      code: 'team',
      label: 'Team',
      minStands: 4,
      maxStands: 6,
      prixMensuel: 12000,
      description: '4 à 6 stands · Pour une agence en croissance',
      couleurHex: 0xFFFF6B35,
    ),
    PlanStands(
      code: 'pro',
      label: 'Pro',
      minStands: 7,
      maxStands: 10,
      prixMensuel: 20000,
      description: '7 à 10 stands · Pour une agence établie',
      couleurHex: 0xFF9C27B0,
    ),
    PlanStands(
      code: 'enterprise',
      label: 'Enterprise',
      minStands: 11,
      maxStands: -1,
      prixMensuel: 30000,
      description: '11 stands et plus · Pour les grandes agences',
      couleurHex: 0xFFFFCC00,
    ),
  ];

  /// Retourne le plan correspondant au nombre de stands
  static PlanStands pourNombreDeStands(int nbStands) {
    for (final plan in tous) {
      if (nbStands >= plan.minStands &&
          (plan.maxStands == -1 || nbStands <= plan.maxStands)) {
        return plan;
      }
    }
    return tous.last;
  }

  static PlanStands fromCode(String code) =>
      tous.firstWhere((p) => p.code == code, orElse: () => tous.first);
}

// ─────────────────────────────────────────────────────────────────────────────
// Statuts
// ─────────────────────────────────────────────────────────────────────────────
enum StatutAbonnement {
  essai('essai', 'Essai gratuit'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Modèle
// ─────────────────────────────────────────────────────────────────────────────
class AbonnementModel {
  final String id;
  final String entrepriseId;
  final String gestionnaireId;
  final PlanStands plan;
  final PeriodeAbonnement periode;
  final StatutAbonnement statut;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montantPaye;
  final int nbStandsSouscrit;
  final DateTime dateCreation;

  const AbonnementModel({
    required this.id,
    required this.entrepriseId,
    required this.gestionnaireId,
    required this.plan,
    required this.periode,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
    required this.montantPaye,
    required this.nbStandsSouscrit,
    required this.dateCreation,
  });

  bool get estActif =>
      (statut == StatutAbonnement.actif || statut == StatutAbonnement.essai) &&
      dateFin.isAfter(DateTime.now());
  bool get estExpire => dateFin.isBefore(DateTime.now());
  int get joursRestants =>
      dateFin.difference(DateTime.now()).inDays.clamp(0, 9999);
  bool get estEssai => statut == StatutAbonnement.essai;

  factory AbonnementModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return AbonnementModel(
      id: id,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      gestionnaireId: (data['gestionnaire_id'] ?? '') as String,
      plan: PlanStands.fromCode((data['plan'] ?? 'solo') as String),
      periode: PeriodeAbonnement.fromCode(
          (data['periode'] ?? 'mensuel') as String),
      statut: StatutAbonnement.fromCode(
          (data['statut'] ?? 'essai') as String),
      dateDebut: (data['date_debut'] as Timestamp).toDate(),
      dateFin: (data['date_fin'] as Timestamp).toDate(),
      montantPaye: ((data['montant_paye'] ?? 0) as num).toDouble(),
      nbStandsSouscrit: (data['nb_stands_souscrit'] ?? 1) as int,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'entreprise_id': entrepriseId,
    'gestionnaire_id': gestionnaireId,
    'plan': plan.code,
    'periode': periode.code,
    'statut': statut.code,
    'date_debut': Timestamp.fromDate(dateDebut),
    'date_fin': Timestamp.fromDate(dateFin),
    'montant_paye': montantPaye,
    'nb_stands_souscrit': nbStandsSouscrit,
    'date_creation': Timestamp.fromDate(dateCreation),
  };
}

// Ancien enum gardé pour compatibilité (non utilisé dans les nouveaux écrans)
enum PlanAbonnement {
  essai('essai_gratuit', 'Essai Gratuit', 0, 2, 30, 'Découvrez SikaFlow', 0xFFFFCC00),
  starter('starter', 'Starter', 5000, 5, 30, "Jusqu'à 5 agents", 0xFF4CAF50),
  business('business', 'Business', 15000, 20, 30, "Jusqu'à 20 agents", 0xFF2196F3),
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

  String get prixFormate =>
      prix == 0 ? 'Gratuit' : '${prix.toString()} FCFA/mois';
  String get maxAgentsLabel =>
      maxAgents == -1 ? 'Illimité' : '$maxAgents agents max';

  static PlanAbonnement fromCode(String code) =>
      PlanAbonnement.values.firstWhere((p) => p.code == code,
          orElse: () => PlanAbonnement.essai);
}
