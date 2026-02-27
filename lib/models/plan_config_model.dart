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
  final String  code;
  final String  label;
  final int     minStands;
  final int     maxStands;    // -1 = illimité
  final int     prixMensuel;  // FCFA
  final String  description;
  final int     couleurHex;
  final bool    actif;
  final int     ordre;        // pour le tri

  const PlanConfig({
    required this.code,
    required this.label,
    required this.minStands,
    required this.maxStands,
    required this.prixMensuel,
    required this.description,
    required this.couleurHex,
    this.actif = true,
    this.ordre = 0,
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
  // NOTE : sur Web, Firestore JS SDK retourne tous les nombres comme `num`
  // (double/JSNumber), jamais comme `int` natif. On utilise donc (num).toInt()
  // au lieu de `as int` pour éviter un TypeError silencieux qui ferait tomber
  // la lecture en fallback kPlansParDefaut.
  factory PlanConfig.fromMap(Map<String, dynamic> m) => PlanConfig(
        code:        (m['code']        ?? '') as String,
        label:       (m['label']       ?? '') as String,
        minStands:   ((m['min_stands']  ?? 1)  as num).toInt(),
        maxStands:   ((m['max_stands']  ?? -1) as num).toInt(),
        prixMensuel: ((m['prix_mensuel']?? 0)  as num).toInt(),
        description: (m['description'] ?? '') as String,
        couleurHex:  ((m['couleur_hex'] ?? 0xFF4CAF50) as num).toInt(),
        actif:       (m['actif']       ?? true) as bool,
        ordre:       ((m['ordre']       ?? 0)  as num).toInt(),
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
      };

  PlanConfig copyWith({
    String?  code,
    String?  label,
    int?     minStands,
    int?     maxStands,
    int?     prixMensuel,
    String?  description,
    int?     couleurHex,
    bool?    actif,
    int?     ordre,
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
        dureeEssaiJours: ((m['duree_essai_jours'] ?? 30) as num).toInt(),
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
  {'code':'solo',       'label':'Solo',       'min_stands':1,  'max_stands':1,  'prix_mensuel':3000,  'description':'1 stand · Idéal pour démarrer',               'couleur_hex':0xFF4CAF50,'actif':true,'ordre':1},
  {'code':'duo',        'label':'Duo',        'min_stands':2,  'max_stands':3,  'prix_mensuel':6000,  'description':'2 à 3 stands · Pour une petite agence',       'couleur_hex':0xFF2196F3,'actif':true,'ordre':2},
  {'code':'team',       'label':'Team',       'min_stands':4,  'max_stands':6,  'prix_mensuel':12000, 'description':'4 à 6 stands · Pour une agence en croissance', 'couleur_hex':0xFFFF6B35,'actif':true,'ordre':3},
  {'code':'pro',        'label':'Pro',        'min_stands':7,  'max_stands':10, 'prix_mensuel':20000, 'description':'7 à 10 stands · Pour une agence établie',      'couleur_hex':0xFF9C27B0,'actif':true,'ordre':4},
  {'code':'enterprise', 'label':'Enterprise', 'min_stands':11, 'max_stands':-1, 'prix_mensuel':30000, 'description':'11 stands et plus · Pour les grandes agences', 'couleur_hex':0xFFFFCC00,'actif':true,'ordre':5},
];

// ── Service Firestore pour la config ───────────────────────────────────────
class ConfigAbonnementService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'config_abonnement';

  // ── Parseur universel Web + natif ────────────────────────────────────────
  // Le SDK Firebase JS (Web) retourne des Map<Object?,Object?> et des num.
  // On normalise systématiquement pour éviter tout TypeError silencieux.
  static Map<String, dynamic> _normaliserMap(Map raw) {
    return Map<String, dynamic>.fromEntries(
      raw.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  static List<PlanConfig> _parseItems(dynamic rawItems) {
    if (rawItems == null || rawItems is! List || rawItems.isEmpty) return [];
    final result = <PlanConfig>[];
    for (final e in rawItems) {
      try {
        result.add(PlanConfig.fromMap(_normaliserMap(e as Map)));
      } catch (err) {
        debugPrint('[ConfigAbonnementService] _parseItems skip: $err');
      }
    }
    return result;
  }

  // ── Stream principal (SEULE SOURCE DE VÉRITÉ pour l'UI) ─────────────────
  // Utilise snapshots() en temps réel.
  // Avec persistenceEnabled:false (main.dart), chaque snapshot vient du serveur.
  // Ne retourne JAMAIS kPlansParDefaut — retourne une liste vide si absent.
  static Stream<List<PlanConfig>> plansStream() {
    return _db
        .collection(_col)
        .doc('plans')
        .snapshots(includeMetadataChanges: false)
        .where((doc) => !doc.metadata.isFromCache) // ignorer les snapshots depuis le cache
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        debugPrint('[ConfigAbonnementService] stream: document absent');
        return <PlanConfig>[];
      }
      final items = _parseItems(doc.data()!['items']);
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      debugPrint('[ConfigAbonnementService] stream: ${items.length} plans (${items.where((p) => p.actif).length} actifs)');
      return items;
    });
  }

  static Stream<ConfigAbonnementGlobal> globalStream() {
    return _db
        .collection(_col)
        .doc('global')
        .snapshots(includeMetadataChanges: false)
        .where((doc) => !doc.metadata.isFromCache)
        .map((doc) {
      if (!doc.exists || doc.data() == null) return const ConfigAbonnementGlobal();
      try {
        return ConfigAbonnementGlobal.fromMap(_normaliserMap(doc.data()!));
      } catch (e) {
        debugPrint('[ConfigAbonnementService] globalStream parse ERROR: $e');
        return const ConfigAbonnementGlobal();
      }
    });
  }

  // ── Lecture ponctuelle (utilisée par l'écran admin pour l'édition) ───────
  static Future<List<PlanConfig>> chargerPlans() async {
    try {
      final doc = await _db.collection(_col).doc('plans').get();
      if (!doc.exists || doc.data() == null) return [];
      final items = _parseItems(doc.data()!['items']);
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      debugPrint('[ConfigAbonnementService] chargerPlans: ${items.length} plans');
      return items;
    } catch (e) {
      debugPrint('[ConfigAbonnementService] chargerPlans ERROR: $e');
      return [];
    }
  }

  static Future<ConfigAbonnementGlobal> chargerGlobal() async {
    try {
      final doc = await _db.collection(_col).doc('global').get();
      if (!doc.exists || doc.data() == null) return const ConfigAbonnementGlobal();
      return ConfigAbonnementGlobal.fromMap(_normaliserMap(doc.data()!));
    } catch (e) {
      debugPrint('[ConfigAbonnementService] chargerGlobal ERROR: $e');
      return const ConfigAbonnementGlobal();
    }
  }

  // ── Sauvegarder ──────────────────────────────────────────────────────────
  static Future<void> sauvegarderPlans(List<PlanConfig> plans) async {
    await _db.collection(_col).doc('plans').set({
      'items': plans.map((p) => p.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    debugPrint('[ConfigAbonnementService] ${plans.length} plans sauvegardés');
  }

  static Future<void> sauvegarderGlobal(ConfigAbonnementGlobal config) async {
    await _db.collection(_col).doc('global').set(config.toMap());
    debugPrint('[ConfigAbonnementService] config globale sauvegardée');
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
