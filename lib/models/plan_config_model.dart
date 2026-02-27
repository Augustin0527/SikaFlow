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
  final String code;
  final String label;
  final int    minStands;
  final int    maxStands;    // -1 = illimité
  final int    prixMensuel;  // FCFA
  final String description;
  final int    couleurHex;
  final bool   actif;
  final int    ordre;

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

  // Sur Web, Firestore JS SDK retourne les nombres comme `num`.
  // On utilise (as num).toInt() pour éviter tout TypeError silencieux.
  factory PlanConfig.fromMap(Map<String, dynamic> m) => PlanConfig(
        code:        (m['code']         ?? '') as String,
        label:       (m['label']        ?? '') as String,
        minStands:   ((m['min_stands']  ?? 1)  as num).toInt(),
        maxStands:   ((m['max_stands']  ?? -1) as num).toInt(),
        prixMensuel: ((m['prix_mensuel']?? 0)  as num).toInt(),
        description: (m['description']  ?? '') as String,
        couleurHex:  ((m['couleur_hex'] ?? 0xFF4CAF50) as num).toInt(),
        actif:       (m['actif']        ?? true) as bool,
        ordre:       ((m['ordre']       ?? 0)  as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'code':         code,
        'label':        label,
        'min_stands':   minStands,
        'max_stands':   maxStands,
        'prix_mensuel': prixMensuel,
        'description':  description,
        'couleur_hex':  couleurHex,
        'actif':        actif,
        'ordre':        ordre,
      };

  PlanConfig copyWith({
    String? code,  String? label,  int? minStands, int? maxStands,
    int? prixMensuel, String? description, int? couleurHex,
    bool? actif, int? ordre,
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
  final int     dureeEssaiJours;
  final double  remiseAnnuelle;
  final bool    essaiActif;
  final String  messagePromo;
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
        dureeEssaiJours: ((m['duree_essai_jours'] ?? 30)   as num).toInt(),
        remiseAnnuelle:  ((m['remise_annuelle']   ?? 0.20) as num).toDouble(),
        essaiActif:      (m['essai_actif']        ?? true) as bool,
        messagePromo:    (m['message_promo']      ?? '')   as String,
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
    int? dureeEssaiJours, double? remiseAnnuelle,
    bool? essaiActif,     String? messagePromo,
  }) => ConfigAbonnementGlobal(
    dureeEssaiJours: dureeEssaiJours ?? this.dureeEssaiJours,
    remiseAnnuelle:  remiseAnnuelle  ?? this.remiseAnnuelle,
    essaiActif:      essaiActif      ?? this.essaiActif,
    messagePromo:    messagePromo    ?? this.messagePromo,
  );
}

// ── Plans par défaut — UNIQUEMENT pour planPourNombreDeStands() ────────────
// Ces valeurs ne sont JAMAIS affichées sur la landing page.
const List<Map<String, dynamic>> kPlansParDefaut = [
  {'code':'duo',        'label':'Duo',        'min_stands':1,  'max_stands':4,  'prix_mensuel':3000,  'description':'', 'couleur_hex':0xFF2196F3,'actif':true,'ordre':1},
  {'code':'pro',        'label':'Pro',        'min_stands':5,  'max_stands':8,  'prix_mensuel':5000,  'description':'', 'couleur_hex':0xFFFF6B35,'actif':true,'ordre':2},
  {'code':'enterprise', 'label':'Enterprise', 'min_stands':10, 'max_stands':-1, 'prix_mensuel':10000, 'description':'', 'couleur_hex':0xFFFFCC00,'actif':true,'ordre':3},
];

// ── Service Firestore ──────────────────────────────────────────────────────
class ConfigAbonnementService {
  static final _db  = FirebaseFirestore.instance;
  static const _col = 'config_abonnement';

  // Normalise Map<Object?,Object?> (Firebase JS SDK) → Map<String,dynamic>
  static Map<String, dynamic> _normaliserMap(Map raw) =>
      Map<String, dynamic>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );

  static List<PlanConfig> _parseItems(dynamic rawItems) {
    if (rawItems == null || rawItems is! List || rawItems.isEmpty) return [];
    final result = <PlanConfig>[];
    for (final e in rawItems) {
      try {
        result.add(PlanConfig.fromMap(_normaliserMap(e as Map)));
      } catch (err) {
        debugPrint('[Plans] parse item error: $err');
      }
    }
    return result;
  }

  // ── Lecture Firestore (persistenceEnabled:false dans main.dart = toujours réseau) ──
  static Future<List<PlanConfig>> chargerPlans() async {
    try {
      final doc = await _db.collection(_col).doc('plans').get();
      if (!doc.exists || doc.data() == null) {
        debugPrint('[Plans] document plans absent');
        return [];
      }
      final items = _parseItems(doc.data()!['items']);
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      debugPrint('[Plans] chargerPlans OK: ${items.length} plans');
      return items;
    } catch (e) {
      debugPrint('[Plans] chargerPlans ERROR: $e');
      return [];
    }
  }

  static Future<ConfigAbonnementGlobal> chargerGlobal() async {
    try {
      final doc = await _db.collection(_col).doc('global').get();
      if (!doc.exists || doc.data() == null) return const ConfigAbonnementGlobal();
      return ConfigAbonnementGlobal.fromMap(_normaliserMap(doc.data()!));
    } catch (e) {
      debugPrint('[Plans] chargerGlobal ERROR: $e');
      return const ConfigAbonnementGlobal();
    }
  }

  // ── Streams temps réel (pour l'écran admin uniquement) ────────────────────
  static Stream<List<PlanConfig>> plansStream() {
    return _db.collection(_col).doc('plans').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return <PlanConfig>[];
      final items = _parseItems(doc.data()!['items']);
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      return items;
    });
  }

  static Stream<ConfigAbonnementGlobal> globalStream() {
    return _db.collection(_col).doc('global').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return const ConfigAbonnementGlobal();
      try {
        return ConfigAbonnementGlobal.fromMap(_normaliserMap(doc.data()!));
      } catch (e) {
        return const ConfigAbonnementGlobal();
      }
    });
  }

  // ── Sauvegarder ──────────────────────────────────────────────────────────
  static Future<void> sauvegarderPlans(List<PlanConfig> plans) async {
    await _db.collection(_col).doc('plans').set({
      'items':      plans.map((p) => p.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    debugPrint('[Plans] ${plans.length} plans sauvegardés');
  }

  static Future<void> sauvegarderGlobal(ConfigAbonnementGlobal config) async {
    await _db.collection(_col).doc('global').set(config.toMap());
    debugPrint('[Plans] config globale sauvegardée');
  }

  // ── Sélectionner le plan pour un nombre de stands ────────────────────────
  static PlanConfig planPourNombreDeStands(List<PlanConfig> plans, int nbStands) {
    final actifs = (plans.isNotEmpty ? plans : kPlansParDefaut.map(PlanConfig.fromMap).toList())
        .where((p) => p.actif).toList()
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
