import 'package:cloud_firestore/cloud_firestore.dart';
import 'entreprise_model.dart';

// ─── Modèle SIM ──────────────────────────────────────────────────────────────
class SimCard {
  final String operateur; // MTN | Moov | Celtiis
  final String numero;
  final double solde;
  final bool actif;

  const SimCard({
    required this.operateur,
    required this.numero,
    required this.solde,
    this.actif = true,
  });

  Operateur get operateurEnum => Operateur.fromCode(operateur);

  SimCard copyWith({String? operateur, String? numero, double? solde, bool? actif}) {
    return SimCard(
      operateur: operateur ?? this.operateur,
      numero: numero ?? this.numero,
      solde: solde ?? this.solde,
      actif: actif ?? this.actif,
    );
  }

  factory SimCard.fromMap(Map<String, dynamic> data) => SimCard(
    operateur: (data['operateur'] ?? 'MTN') as String,
    numero: (data['numero'] ?? '') as String,
    solde: ((data['solde'] ?? 0) as num).toDouble(),
    actif: (data['actif'] ?? true) as bool,
  );

  Map<String, dynamic> toMap() => {
    'operateur': operateur,
    'numero': numero,
    'solde': solde,
    'actif': actif,
  };
}

// ─── Historique affectation agent ────────────────────────────────────────────
class AffectationAgent {
  final String agentId;
  final String agentNom;
  final DateTime dateDebut;
  final DateTime? dateFin;

  const AffectationAgent({
    required this.agentId,
    required this.agentNom,
    required this.dateDebut,
    this.dateFin,
  });

  factory AffectationAgent.fromMap(Map<String, dynamic> data) => AffectationAgent(
    agentId: (data['agent_id'] ?? '') as String,
    agentNom: (data['agent_nom'] ?? '') as String,
    dateDebut: (data['date_debut'] as Timestamp).toDate(),
    dateFin: (data['date_fin'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'agent_id': agentId,
    'agent_nom': agentNom,
    'date_debut': Timestamp.fromDate(dateDebut),
    'date_fin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
  };
}

// ─── Modèle Stand ─────────────────────────────────────────────────────────────
class StandModel {
  final String id;
  final String nom;
  final String lieu;
  final String entrepriseId;
  final String? agentActuelId;
  final String? agentActuelNom;
  final DateTime? dateAffectationAgent;
  final List<SimCard> sims;
  final double soldeEspeces;
  final List<AffectationAgent> historiqueAgents;
  final bool actif;
  final String? latitude;
  final String? longitude;
  final DateTime dateCreation;

  const StandModel({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.entrepriseId,
    this.agentActuelId,
    this.agentActuelNom,
    this.dateAffectationAgent,
    required this.sims,
    required this.soldeEspeces,
    this.historiqueAgents = const [],
    this.actif = true,
    this.latitude,
    this.longitude,
    required this.dateCreation,
  });

  // Solde total SIM (toutes SIMs confondues)
  double get soldeTotalSim => sims.fold(0.0, (acc, s) => acc + s.solde);

  // Solde SIM par opérateur
  double soldeSim(String operateur) {
    final sim = sims.where((s) => s.operateur == operateur && s.actif);
    return sim.fold(0.0, (acc, s) => acc + s.solde);
  }

  // Capital total du stand
  double get capitalTotal => soldeEspeces + soldeTotalSim;

  // Niveau d'alerte espèces
  String niveauAlerteEspeces(double seuilAlerte, double seuilCritique) {
    if (soldeEspeces <= seuilCritique) return 'critique';
    if (soldeEspeces <= seuilAlerte) return 'alerte';
    return 'normal';
  }

  // Niveau d'alerte SIM
  String niveauAlerteSim(String operateur, double seuilAlerte, double seuilCritique) {
    final solde = soldeSim(operateur);
    if (solde <= seuilCritique) return 'critique';
    if (solde <= seuilAlerte) return 'alerte';
    return 'normal';
  }

  factory StandModel.fromFirestore(Map<String, dynamic> data, String id) {
    return StandModel(
      id: id,
      nom: (data['nom'] ?? '') as String,
      lieu: (data['lieu'] ?? '') as String,
      entrepriseId: (data['entreprise_id'] ?? '') as String,
      agentActuelId: data['agent_actuel_id'] as String?,
      agentActuelNom: data['agent_actuel_nom'] as String?,
      dateAffectationAgent: (data['date_affectation_agent'] as Timestamp?)?.toDate(),
      sims: ((data['sims'] as List<dynamic>?) ?? [])
          .map((s) => SimCard.fromMap(s as Map<String, dynamic>))
          .toList(),
      soldeEspeces: ((data['solde_especes'] ?? 0) as num).toDouble(),
      historiqueAgents: ((data['historique_agents'] as List<dynamic>?) ?? [])
          .map((h) => AffectationAgent.fromMap(h as Map<String, dynamic>))
          .toList(),
      actif: (data['actif'] ?? true) as bool,
      latitude: data['latitude'] as String?,
      longitude: data['longitude'] as String?,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'nom': nom,
    'lieu': lieu,
    'entreprise_id': entrepriseId,
    'agent_actuel_id': agentActuelId,
    'agent_actuel_nom': agentActuelNom,
    'date_affectation_agent': dateAffectationAgent != null
        ? Timestamp.fromDate(dateAffectationAgent!)
        : null,
    'sims': sims.map((s) => s.toMap()).toList(),
    'solde_especes': soldeEspeces,
    'historique_agents': historiqueAgents.map((h) => h.toMap()).toList(),
    'actif': actif,
    'latitude': latitude,
    'longitude': longitude,
    'date_creation': Timestamp.fromDate(dateCreation),
  };
}
