import 'package:cloud_firestore/cloud_firestore.dart';
import 'entreprise_model.dart';

// ─── Opération détaillée ──────────────────────────────────────────────────────
class OperationModel {
  final String id;
  final String standId;
  final String standNom;
  final String agentId;
  final String agentNom;
  final String entrepriseId;
  final String operateur; // MTN | Moov | Celtiis
  final String typeOperation; // depot | retrait | credit_forfait
  final double montant;
  final double ristourneCalculee;
  final String? numeroClient;
  final String? nomClient;
  final DateTime dateHeure;
  final bool modifiable; // dans le délai configuré
  final bool modifie; // a été modifié
  final String? motifModification;
  final DateTime? dateModification;
  final String? modifiePar;
  final String modeSaisie; // detail | synthese

  const OperationModel({
    required this.id,
    required this.standId,
    required this.standNom,
    required this.agentId,
    required this.agentNom,
    required this.entrepriseId,
    required this.operateur,
    required this.typeOperation,
    required this.montant,
    required this.ristourneCalculee,
    this.numeroClient,
    this.nomClient,
    required this.dateHeure,
    required this.modifiable,
    this.modifie = false,
    this.motifModification,
    this.dateModification,
    this.modifiePar,
    this.modeSaisie = 'detail',
  });

  TypeOperation get typeEnum => TypeOperation.fromCode(typeOperation);
  Operateur get operateurEnum => Operateur.fromCode(operateur);

  // Impact sur espèces et SIM
  // Dépôt    → espèces ↑, SIM ↓
  // Retrait  → espèces ↓, SIM ↑
  // Crédit   → espèces ↑, SIM ↓
  double get impactEspeces {
    switch (typeOperation) {
      case 'depot':         return montant;   // espèces augmentent
      case 'retrait':       return -montant;  // espèces diminuent
      case 'credit_forfait':return montant;   // espèces augmentent
      default:              return 0;
    }
  }

  double get impactSim {
    switch (typeOperation) {
      case 'depot':         return -montant;  // SIM diminue
      case 'retrait':       return montant;   // SIM augmente
      case 'credit_forfait':return -montant;  // SIM diminue
      default:              return 0;
    }
  }

  factory OperationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OperationModel(
      id: id,
      standId: (data['stand_id'] ?? '') as String,
      standNom: (data['stand_nom'] ?? '') as String,
      agentId: (data['agent_id'] ?? '') as String,
      agentNom: (data['agent_nom'] ?? '') as String,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      operateur: (data['operateur'] ?? 'MTN') as String,
      typeOperation: (data['type_operation'] ?? 'depot') as String,
      montant: ((data['montant'] ?? 0) as num).toDouble(),
      ristourneCalculee: ((data['ristourne_calculee'] ?? 0) as num).toDouble(),
      numeroClient: data['numero_client'] as String?,
      nomClient: data['nom_client'] as String?,
      dateHeure: (data['date_heure'] as Timestamp).toDate(),
      modifiable: (data['modifiable'] ?? false) as bool,
      modifie: (data['modifie'] ?? false) as bool,
      motifModification: data['motif_modification'] as String?,
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      modifiePar: data['modifie_par'] as String?,
      modeSaisie: (data['mode_saisie'] ?? 'detail') as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'stand_id': standId,
    'stand_nom': standNom,
    'agent_id': agentId,
    'agent_nom': agentNom,
    'entreprise_id': entrepriseId,
    'operateur': operateur,
    'type_operation': typeOperation,
    'montant': montant,
    'ristourne_calculee': ristourneCalculee,
    'numero_client': numeroClient,
    'nom_client': nomClient,
    'date_heure': Timestamp.fromDate(dateHeure),
    'modifiable': modifiable,
    'modifie': modifie,
    'motif_modification': motifModification,
    'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
    'modifie_par': modifiePar,
    'mode_saisie': modeSaisie,
  };
}

// ─── Synthèse journalière ─────────────────────────────────────────────────────
class SyntheseJournaliere {
  final String id;
  final String standId;
  final String agentId;
  final String entrepriseId;
  final DateTime date;
  final Map<String, StatOperateur> parOperateur; // clé = operateur
  final double soldeEspecesFin;
  final double ristournesTotales;

  const SyntheseJournaliere({
    required this.id,
    required this.standId,
    required this.agentId,
    required this.entrepriseId,
    required this.date,
    required this.parOperateur,
    required this.soldeEspecesFin,
    required this.ristournesTotales,
  });
}

class StatOperateur {
  final double totalDepots;
  final double totalRetraits;
  final double totalCredits;
  final int nbDepots;
  final int nbRetraits;
  final int nbCredits;
  final double ristournes;

  const StatOperateur({
    this.totalDepots = 0,
    this.totalRetraits = 0,
    this.totalCredits = 0,
    this.nbDepots = 0,
    this.nbRetraits = 0,
    this.nbCredits = 0,
    this.ristournes = 0,
  });

  double get totalOperations => totalDepots + totalRetraits + totalCredits;
  int get nbOperations => nbDepots + nbRetraits + nbCredits;
}

// ─── Taux de ristourne ───────────────────────────────────────────────────────
class TauxRistourne {
  final String id;
  final String entrepriseId;
  final String operateur;
  final String typeOperation;
  final double taux; // ex: 0.005 = 0.5%
  final DateTime dateDebut;
  final DateTime? dateFin;

  const TauxRistourne({
    required this.id,
    required this.entrepriseId,
    required this.operateur,
    required this.typeOperation,
    required this.taux,
    required this.dateDebut,
    this.dateFin,
  });

  bool isActifPour(DateTime date) {
    if (date.isBefore(dateDebut)) return false;
    if (dateFin != null && date.isAfter(dateFin!)) return false;
    return true;
  }

  double calculerRistourne(double montant) => montant * taux;

  String get tauxPourcentage => '${(taux * 100).toStringAsFixed(2)}%';

  factory TauxRistourne.fromFirestore(Map<String, dynamic> data, String id) {
    return TauxRistourne(
      id: id,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      operateur: (data['operateur'] ?? 'MTN') as String,
      typeOperation: (data['type_operation'] ?? 'depot') as String,
      taux: ((data['taux'] ?? 0) as num).toDouble(),
      dateDebut: (data['date_debut'] as Timestamp).toDate(),
      dateFin: (data['date_fin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'entreprise_id': entrepriseId,
    'operateur': operateur,
    'type_operation': typeOperation,
    'taux': taux,
    'date_debut': Timestamp.fromDate(dateDebut),
    'date_fin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
  };
}

// ─── Demande de rééquilibrage ─────────────────────────────────────────────────
class DemandeReequilibrage {
  final String id;
  final String standId;
  final String standNom;
  final String agentId;
  final String agentNom;
  final String entrepriseId;
  final String type; // especes_vers_sim | sim_vers_especes | sim_vers_sim
  final String? operateurSource;
  final String? operateurDestination;
  final double montant;
  final String motif;
  final String statut; // en_attente | approuve | refuse
  final DateTime dateDemande;
  final DateTime? dateTraitement;
  final String? traitePar;
  final String? motifRefus;

  const DemandeReequilibrage({
    required this.id,
    required this.standId,
    required this.standNom,
    required this.agentId,
    required this.agentNom,
    required this.entrepriseId,
    required this.type,
    this.operateurSource,
    this.operateurDestination,
    required this.montant,
    required this.motif,
    required this.statut,
    required this.dateDemande,
    this.dateTraitement,
    this.traitePar,
    this.motifRefus,
  });

  bool get estEnAttente => statut == 'en_attente';

  factory DemandeReequilibrage.fromFirestore(Map<String, dynamic> data, String id) {
    return DemandeReequilibrage(
      id: id,
      standId: (data['stand_id'] ?? '') as String,
      standNom: (data['stand_nom'] ?? '') as String,
      agentId: (data['agent_id'] ?? '') as String,
      agentNom: (data['agent_nom'] ?? '') as String,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      operateurSource: data['operateur_source'] as String?,
      operateurDestination: data['operateur_destination'] as String?,
      montant: ((data['montant'] ?? 0) as num).toDouble(),
      motif: (data['motif'] ?? '') as String,
      statut: (data['statut'] ?? 'en_attente') as String,
      dateDemande: (data['date_demande'] as Timestamp).toDate(),
      dateTraitement: (data['date_traitement'] as Timestamp?)?.toDate(),
      traitePar: data['traite_par'] as String?,
      motifRefus: data['motif_refus'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'stand_id': standId,
    'stand_nom': standNom,
    'agent_id': agentId,
    'agent_nom': agentNom,
    'entreprise_id': entrepriseId,
    'type': type,
    'operateur_source': operateurSource,
    'operateur_destination': operateurDestination,
    'montant': montant,
    'motif': motif,
    'statut': statut,
    'date_demande': Timestamp.fromDate(dateDemande),
    'date_traitement': dateTraitement != null ? Timestamp.fromDate(dateTraitement!) : null,
    'traite_par': traitePar,
    'motif_refus': motifRefus,
  };
}

// ─── Alerte ──────────────────────────────────────────────────────────────────
class AlerteModel {
  final String id;
  final String standId;
  final String standNom;
  final String entrepriseId;
  final String type; // especes_basse | sim_basse | especes_critique | sim_critique
  final String? operateur;
  final double montantActuel;
  final double seuil;
  final bool lue;
  final DateTime dateCreation;

  const AlerteModel({
    required this.id,
    required this.standId,
    required this.standNom,
    required this.entrepriseId,
    required this.type,
    this.operateur,
    required this.montantActuel,
    required this.seuil,
    required this.lue,
    required this.dateCreation,
  });

  bool get estCritique => type.contains('critique');

  factory AlerteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AlerteModel(
      id: id,
      standId: (data['stand_id'] ?? '') as String,
      standNom: (data['stand_nom'] ?? '') as String,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      operateur: data['operateur'] as String?,
      montantActuel: ((data['montant_actuel'] ?? 0) as num).toDouble(),
      seuil: ((data['seuil'] ?? 0) as num).toDouble(),
      lue: (data['lue'] ?? false) as bool,
      dateCreation: (data['date_creation'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'stand_id': standId,
    'stand_nom': standNom,
    'entreprise_id': entrepriseId,
    'type': type,
    'operateur': operateur,
    'montant_actuel': montantActuel,
    'seuil': seuil,
    'lue': lue,
    'date_creation': Timestamp.fromDate(dateCreation),
  };
}

// ─── Mouvement de capital ─────────────────────────────────────────────────────
class MouvementCapital {
  final String id;
  final String standId;
  final String entrepriseId;
  final String effectuePar;
  final String type; // ajout_especes | retrait_especes | ajout_sim | retrait_sim
  final String? operateur;
  final double montant; // positif = ajout, négatif = retrait
  final String motif;
  final DateTime date;

  const MouvementCapital({
    required this.id,
    required this.standId,
    required this.entrepriseId,
    required this.effectuePar,
    required this.type,
    this.operateur,
    required this.montant,
    required this.motif,
    required this.date,
  });

  factory MouvementCapital.fromFirestore(Map<String, dynamic> data, String id) {
    return MouvementCapital(
      id: id,
      standId: (data['stand_id'] ?? '') as String,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      effectuePar: (data['effectue_par'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      operateur: data['operateur'] as String?,
      montant: ((data['montant'] ?? 0) as num).toDouble(),
      motif: (data['motif'] ?? '') as String,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'stand_id': standId,
    'entreprise_id': entrepriseId,
    'effectue_par': effectuePar,
    'type': type,
    'operateur': operateur,
    'montant': montant,
    'motif': motif,
    'date': Timestamp.fromDate(date),
  };
}
