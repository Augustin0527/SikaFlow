/// Modèle représentant un abonnement SikaFlow
class AbonnementModel {
  final String id;
  final String entrepriseId;
  final String gestionnaireId;
  final PlanAbonnement plan;
  final StatutAbonnement statut;
  final DateTime dateDebut;
  final DateTime dateExpiration;
  final double montantPaye;
  final String? fedapayTransactionId;
  final String? fedapayReference;
  final DateTime dateCreation;

  const AbonnementModel({
    required this.id,
    required this.entrepriseId,
    required this.gestionnaireId,
    required this.plan,
    required this.statut,
    required this.dateDebut,
    required this.dateExpiration,
    required this.montantPaye,
    this.fedapayTransactionId,
    this.fedapayReference,
    required this.dateCreation,
  });

  bool get estActif => statut == StatutAbonnement.actif && dateExpiration.isAfter(DateTime.now());
  bool get estExpire => dateExpiration.isBefore(DateTime.now());
  int get joursRestants => dateExpiration.difference(DateTime.now()).inDays;
  bool get expireBientot => joursRestants <= 7 && joursRestants >= 0;

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'entreprise_id': entrepriseId,
    'gestionnaire_id': gestionnaireId,
    'plan': plan.code,
    'statut': statut.code,
    'date_debut': dateDebut.toIso8601String(),
    'date_expiration': dateExpiration.toIso8601String(),
    'montant_paye': montantPaye,
    'fedapay_transaction_id': fedapayTransactionId,
    'fedapay_reference': fedapayReference,
    'date_creation': dateCreation.toIso8601String(),
  };

  factory AbonnementModel.fromFirestore(Map<String, dynamic> data) {
    return AbonnementModel(
      id: data['id'] as String? ?? '',
      entrepriseId: data['entreprise_id'] as String? ?? '',
      gestionnaireId: data['gestionnaire_id'] as String? ?? '',
      plan: PlanAbonnement.fromCode(data['plan'] as String? ?? 'essai'),
      statut: StatutAbonnement.fromCode(data['statut'] as String? ?? 'actif'),
      dateDebut: DateTime.tryParse(data['date_debut'] as String? ?? '') ?? DateTime.now(),
      dateExpiration: DateTime.tryParse(data['date_expiration'] as String? ?? '') ?? DateTime.now(),
      montantPaye: ((data['montant_paye'] ?? 0) as num).toDouble(),
      fedapayTransactionId: data['fedapay_transaction_id'] as String?,
      fedapayReference: data['fedapay_reference'] as String?,
      dateCreation: DateTime.tryParse(data['date_creation'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ── Plans disponibles ────────────────────────────────────────────────────────
enum PlanAbonnement {
  essai(
    code: 'essai',
    nom: 'Essai Gratuit',
    prix: 0,
    agentsMax: 2,
    dureeJours: 30,
    description: '30 jours gratuits pour découvrir SikaFlow',
    couleur: 0xFF6B7280,
    icone: '🎁',
  ),
  starter(
    code: 'starter',
    nom: 'Starter',
    prix: 2000,
    agentsMax: 3,
    dureeJours: 30,
    description: 'Idéal pour les petites structures',
    couleur: 0xFF10B981,
    icone: '🚀',
  ),
  business(
    code: 'business',
    nom: 'Business',
    prix: 5000,
    agentsMax: 10,
    dureeJours: 30,
    description: 'Pour les entreprises en croissance',
    couleur: 0xFF3B82F6,
    icone: '💼',
  ),
  premium(
    code: 'premium',
    nom: 'Premium',
    prix: 10000,
    agentsMax: -1, // illimité
    dureeJours: 30,
    description: 'Agents illimités + toutes fonctionnalités',
    couleur: 0xFFF59E0B,
    icone: '👑',
  );

  const PlanAbonnement({
    required this.code,
    required this.nom,
    required this.prix,
    required this.agentsMax,
    required this.dureeJours,
    required this.description,
    required this.couleur,
    required this.icone,
  });

  final String code;
  final String nom;
  final int prix;
  final int agentsMax; // -1 = illimité
  final int dureeJours;
  final String description;
  final int couleur;
  final String icone;

  String get prixFormate => prix == 0 ? 'Gratuit' : '${prix.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA/mois';
  String get agentsMaxLabel => agentsMax == -1 ? 'Illimité' : '$agentsMax agents max';

  static PlanAbonnement fromCode(String code) {
    return PlanAbonnement.values.firstWhere(
      (p) => p.code == code,
      orElse: () => PlanAbonnement.essai,
    );
  }
}

// ── Statuts d'abonnement ─────────────────────────────────────────────────────
enum StatutAbonnement {
  actif(code: 'actif', label: 'Actif'),
  expire(code: 'expire', label: 'Expiré'),
  suspendu(code: 'suspendu', label: 'Suspendu'),
  annule(code: 'annule', label: 'Annulé');

  const StatutAbonnement({required this.code, required this.label});
  final String code;
  final String label;

  static StatutAbonnement fromCode(String code) {
    return StatutAbonnement.values.firstWhere(
      (s) => s.code == code,
      orElse: () => StatutAbonnement.actif,
    );
  }
}

// ── Modèle transaction FedaPay ───────────────────────────────────────────────
class FedaPayTransaction {
  final int id;
  final String reference;
  final int amount;
  final String status;
  final String? receiptUrl;
  final String? checkoutUrl;

  const FedaPayTransaction({
    required this.id,
    required this.reference,
    required this.amount,
    required this.status,
    this.receiptUrl,
    this.checkoutUrl,
  });

  bool get estApprouve => status == 'approved';
  bool get estEnAttente => status == 'pending';

  factory FedaPayTransaction.fromJson(Map<String, dynamic> json) {
    return FedaPayTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      receiptUrl: json['receipt_url'] as String?,
    );
  }
}
