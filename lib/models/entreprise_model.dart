import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Opérateurs Mobile Money ─────────────────────────────────────────────────
enum Operateur {
  mtn('MTN', 'MTN Mobile Money', 0xFFFFCC00),
  moov('Moov', 'Moov Money', 0xFF0033A0),
  celtiis('Celtiis', 'Celtiis Cash', 0xFF00A651);

  const Operateur(this.code, this.nom, this.couleurHex);
  final String code;
  final String nom;
  final int couleurHex;

  static Operateur fromCode(String code) =>
      Operateur.values.firstWhere((o) => o.code == code, orElse: () => Operateur.mtn);
}

// ─── Types d'opération ───────────────────────────────────────────────────────
enum TypeOperation {
  depot('depot', 'Dépôt', '📥'),
  retrait('retrait', 'Retrait', '📤'),
  creditForfait('credit_forfait', 'Crédit/Forfait', '📶');

  const TypeOperation(this.code, this.label, this.emoji);
  final String code;
  final String label;
  final String emoji;

  static TypeOperation fromCode(String code) =>
      TypeOperation.values.firstWhere((t) => t.code == code, orElse: () => TypeOperation.depot);
}

// ─── Mode de saisie ──────────────────────────────────────────────────────────
enum ModeSaisie { detail, synthese }

// ─── Modèle Entreprise ───────────────────────────────────────────────────────
class EntrepriseModel {
  final String id;
  final String nom;
  final String gestionnaireId;
  final DateTime dateCreation;
  final String statut; // essai | actif | suspendu | expire
  final String plan;
  final DateTime? dateFinEssai;
  final DateTime? dateExpirationAbonnement;

  // Configuration globale
  final ModeSaisie modeSaisie;
  final int delaiModificationHeures; // défaut 30h
  final bool agentsVoientAutresStands;
  final String visibiliteStands; // 'ferme' | 'ouvert' | 'partiel'

  // Seuils d'alerte
  final double seuilAlerteEspeces;
  final double seuilCritiqueEspeces;
  final double seuilAlerteSim;
  final double seuilCritiqueSim;

  const EntrepriseModel({
    required this.id,
    required this.nom,
    required this.gestionnaireId,
    required this.dateCreation,
    required this.statut,
    required this.plan,
    this.dateFinEssai,
    this.dateExpirationAbonnement,
    this.modeSaisie = ModeSaisie.detail,
    this.delaiModificationHeures = 30,
    this.agentsVoientAutresStands = false,
    this.visibiliteStands = 'ferme',
    this.seuilAlerteEspeces = 50000,
    this.seuilCritiqueEspeces = 20000,
    this.seuilAlerteSim = 30000,
    this.seuilCritiqueSim = 10000,
  });

  bool get estActif => statut == 'actif' || statut == 'essai';

  factory EntrepriseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return EntrepriseModel(
      id: id,
      nom: (data['nom'] ?? '') as String,
      gestionnaireId: (data['gestionnaire_id'] ?? '') as String,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: (data['statut'] ?? 'essai') as String,
      plan: (data['plan'] ?? 'essai_gratuit') as String,
      dateFinEssai: (data['date_fin_essai'] as Timestamp?)?.toDate(),
      dateExpirationAbonnement: (data['date_expiration_abonnement'] as Timestamp?)?.toDate(),
      modeSaisie: data['mode_saisie'] == 'synthese' ? ModeSaisie.synthese : ModeSaisie.detail,
      delaiModificationHeures: (data['delai_modification_heures'] ?? 30) as int,
      agentsVoientAutresStands: (data['agents_voient_autres_stands'] ?? false) as bool,
      visibiliteStands: (data['visibilite_stands'] ?? 'ferme') as String,
      seuilAlerteEspeces: ((data['seuil_alerte_especes'] ?? 50000) as num).toDouble(),
      seuilCritiqueEspeces: ((data['seuil_critique_especes'] ?? 20000) as num).toDouble(),
      seuilAlerteSim: ((data['seuil_alerte_sim'] ?? 30000) as num).toDouble(),
      seuilCritiqueSim: ((data['seuil_critique_sim'] ?? 10000) as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'nom': nom,
    'gestionnaire_id': gestionnaireId,
    'date_creation': Timestamp.fromDate(dateCreation),
    'statut': statut,
    'plan': plan,
    'date_fin_essai': dateFinEssai != null ? Timestamp.fromDate(dateFinEssai!) : null,
    'date_expiration_abonnement': dateExpirationAbonnement != null
        ? Timestamp.fromDate(dateExpirationAbonnement!)
        : null,
    'mode_saisie': modeSaisie == ModeSaisie.detail ? 'detail' : 'synthese',
    'delai_modification_heures': delaiModificationHeures,
    'agents_voient_autres_stands': agentsVoientAutresStands,
    'visibilite_stands': visibiliteStands,
    'seuil_alerte_especes': seuilAlerteEspeces,
    'seuil_critique_especes': seuilCritiqueEspeces,
    'seuil_alerte_sim': seuilAlerteSim,
    'seuil_critique_sim': seuilCritiqueSim,
  };
}
