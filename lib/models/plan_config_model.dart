import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION DYNAMIQUE DES PLANS — définie par le super admin
// Stockée dans Firestore : collection "config_abonnement"
//   doc "plans"   → champ "items": List<Map>
//   doc "global"  → durée essai, remise annuelle, essai actif...
// ─────────────────────────────────────────────────────────────────────────────

// ── Plan individuel ────────────────────────────────────────────────────────
class PlanConfig {
  final String       code;
  final String       label;
  final int          minStands;
  final int          maxStands;    // -1 = illimité
  final int          prixMensuel;  // FCFA
  final String       description;
  final int          couleurHex;
  final bool         actif;
  final int          ordre;        // pour le tri
  final List<String> features;     // fonctionnalités listées
  final bool         populaire;    // badge "Populaire"

  const PlanConfig({
    required this.code,
    required this.label,
    required this.minStands,
    required this.maxStands,
    required this.prixMensuel,
    required this.description,
    required this.couleurHex,
    this.actif    = true,
    this.ordre    = 0,
    this.features = const [],
    this.populaire = false,
  });

  // ── Prix calculé selon la période ────────────────────────────────────────
  int prixMensuelAvecRemise(double remise) =>
      (prixMensuel * (1 - remise)).round();

  int totalPeriode(int mois, double remise) =>
      prixMensuelAvecRemise(remise) * mois;

  int economieAnnuelle(double remise) =>
      prixMensuel * 12 - totalPeriode(12, remise);

  String get maxStandsLabel =>
      maxStands == -1
          ? 'Stands illimités'
          : '$maxStands stand${maxStands > 1 ? "s" : ""} max';

  // ── Sérialisation Firestore ───────────────────────────────────────────────
  factory PlanConfig.fromMap(Map<String, dynamic> m) => PlanConfig(
        code:        (m['code']        ?? '') as String,
        label:       (m['label']       ?? '') as String,
        minStands:   (m['min_stands']  ?? 1)  as int,
        maxStands:   (m['max_stands']  ?? -1) as int,
        prixMensuel: (m['prix_mensuel']?? 0)  as int,
        description: (m['description'] ?? '') as String,
        couleurHex:  (m['couleur_hex'] ?? 0xFF4CAF50) as int,
        actif:       (m['actif']       ?? true) as bool,
        ordre:       (m['ordre']       ?? 0)  as int,
        features:    ((m['features']   as List?) ?? []).map((e) => e.toString()).toList(),
        populaire:   (m['populaire']   ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'code':        code,
        'label':       label,
        'min_stands':  minStands,
        'max_stands':  maxStands,
        'prix_mensuel':prixMensuel,
        'description': description,
        'couleur_hex': couleurHex,
        'actif':       actif,
        'ordre':       ordre,
        'features':    features,
        'populaire':   populaire,
      };

  PlanConfig copyWith({
    String?       code,
    String?       label,
    int?          minStands,
    int?          maxStands,
    int?          prixMensuel,
    String?       description,
    int?          couleurHex,
    bool?         actif,
    int?          ordre,
    List<String>? features,
    bool?         populaire,
  }) => PlanConfig(
    code:        code        ?? this.code,
    label:       label       ?? this.label,
    minStands:   minStands   ?? this.minStands,
    maxStands:   maxStands   ?? this.maxStands,
    prixMensuel: prixMensuel ?? this.prixMensuel,
    description: description ?? this.description,
    couleurHex:  couleurHex  ?? this.couleurHex,
    actif:       actif       ?? this.actif,
    ordre:       ordre       ?? this.ordre,
    features:    features    ?? this.features,
    populaire:   populaire   ?? this.populaire,
  );
}

// ── Config globale ─────────────────────────────────────────────────────────
class ConfigAbonnementGlobal {
  final int    dureeEssaiJours;    // défaut 30
  final double remiseAnnuelle;     // 0.20 = 20 %
  final bool   essaiActif;         // afficher ou non l'essai gratuit
  final String messagePromo;       // texte promo affiché sur la landing
  final DateTime? updatedAt;

  const ConfigAbonnementGlobal({
    this.dureeEssaiJours = 30,
    this.remiseAnnuelle  = 0.20,
    this.essaiActif      = true,
    this.messagePromo    = '',
    this.updatedAt,
  });

  factory ConfigAbonnementGlobal.fromMap(Map<String, dynamic> m) =>
      ConfigAbonnementGlobal(
        dureeEssaiJours: (m['duree_essai_jours'] ?? 30) as int,
        remiseAnnuelle:  ((m['remise_annuelle']  ?? 0.20) as num).toDouble(),
        essaiActif:      (m['essai_actif']       ?? true) as bool,
        messagePromo:    (m['message_promo']     ?? '') as String,
        updatedAt:       (m['updated_at'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'duree_essai_jours': dureeEssaiJours,
        'remise_annuelle':   remiseAnnuelle,
        'essai_actif':       essaiActif,
        'message_promo':     messagePromo,
        'updated_at':        FieldValue.serverTimestamp(),
      };

  ConfigAbonnementGlobal copyWith({
    int?    dureeEssaiJours,
    double? remiseAnnuelle,
    bool?   essaiActif,
    String? messagePromo,
  }) => ConfigAbonnementGlobal(
    dureeEssaiJours: dureeEssaiJours ?? this.dureeEssaiJours,
    remiseAnnuelle:  remiseAnnuelle  ?? this.remiseAnnuelle,
    essaiActif:      essaiActif      ?? this.essaiActif,
    messagePromo:    messagePromo    ?? this.messagePromo,
  );
}

// ── Plans par défaut (utilisés si Firestore est vide) ──────────────────────
const List<Map<String, dynamic>> kPlansParDefaut = [
  {
    'code':'solo', 'label':'Solo', 'min_stands':1, 'max_stands':1,
    'prix_mensuel':1200, 'description':'Parfait pour démarrer avec 1 stand',
    'couleur_hex':0xFF4CAF50, 'actif':true, 'ordre':1, 'populaire':false,
    'features':['1 stand','Tableau de bord complet','Gestion des opérations','Rapports journaliers','Support email'],
  },
  {
    'code':'pro', 'label':'Pro', 'min_stands':2, 'max_stands':5,
    'prix_mensuel':5000, 'description':'Pour les agences en croissance',
    'couleur_hex':0xFFFF6B35, 'actif':true, 'ordre':2, 'populaire':true,
    'features':['Jusqu\'à 5 stands','Tout le plan Solo','Multi-agents & contrôleurs','Alertes automatiques','Rapports avancés','Support prioritaire'],
  },
  {
    'code':'enterprise', 'label':'Entreprise', 'min_stands':6, 'max_stands':-1,
    'prix_mensuel':10000, 'description':'Pour les grandes agences, stands illimités',
    'couleur_hex':0xFFFFCC00, 'actif':true, 'ordre':3, 'populaire':false,
    'features':['Stands illimités','Tout le plan Pro','API & intégrations','SLA garanti 99.9%','Gestionnaire dédié','Formation incluse'],
  },
];

// ── Service Firestore pour la config ───────────────────────────────────────
class ConfigAbonnementService {
  // ⚠️ NE PAS utiliser static final _db = FirebaseFirestore.instance ici !
  // Les champs statiques sont initialisés lors de la première référence à la classe,
  // ce qui peut se produire AVANT Firebase.initializeApp() sur Web.
  // On utilise un getter lazy pour s'assurer que Firebase est prêt.
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static const _col = 'config_abonnement';

  // ── Charger tous les plans ───────────────────────────────────────────────
  static Future<List<PlanConfig>> chargerPlans() async {
    try {
      final doc = await _db.collection(_col).doc('plans').get();
      if (!doc.exists) {
        await _initialiserPlansParDefaut();
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }
      final items = (doc.data()?['items'] as List?)
          ?.map((e) => PlanConfig.fromMap(e as Map<String, dynamic>))
          .toList() ?? [];
      if (items.isEmpty) {
        await _initialiserPlansParDefaut();
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      return items;
    } catch (e) {
      debugPrint('[ConfigAbonnementService] chargerPlans error: $e');
      return kPlansParDefaut.map(PlanConfig.fromMap).toList();
    }
  }

  // ── Stream en temps réel ─────────────────────────────────────────────────
  static Stream<List<PlanConfig>> plansStream() {
    return _db.collection(_col).doc('plans').snapshots().map((doc) {
      if (!doc.exists) return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      final items = (doc.data()?['items'] as List?)
          ?.map((e) => PlanConfig.fromMap(e as Map<String, dynamic>))
          .toList() ?? [];
      if (items.isEmpty) return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      return items;
    });
  }

  // ── Charger config globale ───────────────────────────────────────────────
  static Future<ConfigAbonnementGlobal> chargerGlobal() async {
    try {
      final doc = await _db.collection(_col).doc('global').get();
      if (!doc.exists) return const ConfigAbonnementGlobal();
      return ConfigAbonnementGlobal.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[ConfigAbonnementService] chargerGlobal error: $e');
      return const ConfigAbonnementGlobal();
    }
  }

  // ── Stream config globale ────────────────────────────────────────────────
  static Stream<ConfigAbonnementGlobal> globalStream() {
    return _db.collection(_col).doc('global').snapshots().map((doc) {
      if (!doc.exists) return const ConfigAbonnementGlobal();
      return ConfigAbonnementGlobal.fromMap(doc.data()!);
    });
  }

  // ── Sauvegarder tous les plans ───────────────────────────────────────────
  static Future<void> sauvegarderPlans(List<PlanConfig> plans) async {
    await _db.collection(_col).doc('plans').set({
      'items': plans.map((p) => p.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Sauvegarder config globale ───────────────────────────────────────────
  static Future<void> sauvegarderGlobal(ConfigAbonnementGlobal config) async {
    await _db.collection(_col).doc('global').set(config.toMap());
  }

  // ── Initialiser avec les plans par défaut ────────────────────────────────
  static Future<void> _initialiserPlansParDefaut() async {
    await _db.collection(_col).doc('plans').set({
      'items': kPlansParDefaut,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await _db.collection(_col).doc('global').set(
      const ConfigAbonnementGlobal().toMap(),
    );
  }

  // ── Trouver le plan correspondant à un nombre de stands ──────────────────
  static PlanConfig planPourNombreDeStands(List<PlanConfig> plans, int nbStands) {
    final actifs = plans.where((p) => p.actif).toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    for (final plan in actifs) {
      if (nbStands >= plan.minStands &&
          (plan.maxStands == -1 || nbStands <= plan.maxStands)) {
        return plan;
      }
    }
    return actifs.isNotEmpty ? actifs.last : PlanConfig.fromMap(kPlansParDefaut.last);
  }
}
