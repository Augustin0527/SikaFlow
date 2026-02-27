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

  // ── Parseur sécurisé (Web + natif) ──────────────────────────────────────
  // Sur Web, Firestore JS retourne des Map<Object?,Object?> et des num au lieu
  // de Map<String,dynamic> et int. On normalise ici.
  static List<PlanConfig> _parseItems(dynamic rawItems) {
    if (rawItems == null || rawItems is! List) return [];
    final result = <PlanConfig>[];
    for (final e in rawItems) {
      try {
        // Convertit Map<Object?,Object?> → Map<String,dynamic>
        final map = Map<String, dynamic>.fromEntries(
          (e as Map).entries.map((entry) =>
            MapEntry(entry.key.toString(), entry.value),
          ),
        );
        result.add(PlanConfig.fromMap(map));
      } catch (err) {
        debugPrint('[ConfigAbonnementService] _parseItems skip item: $err');
      }
    }
    return result;
  }

  // ── Charger tous les plans (lecture réseau forcée, sans cache) ───────────
  static Future<List<PlanConfig>> chargerPlans() async {
    try {
      // GetOptions(source: Source.server) force la lecture depuis le serveur
      // et évite le snapshot cache vide qui déclenchait l'initialisation
      final doc = await _db.collection(_col).doc('plans')
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        debugPrint('[ConfigAbonnementService] plans doc absent sur serveur');
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }

      final items = _parseItems(doc.data()?['items']);
      if (items.isEmpty) {
        debugPrint('[ConfigAbonnementService] items vide (serveur)');
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }

      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      debugPrint('[ConfigAbonnementService] ${items.length} plans chargés depuis serveur');
      return items;
    } catch (e, st) {
      debugPrint('[ConfigAbonnementService] chargerPlans ERROR: $e\n$st');
      // Dernier recours : lecture depuis le cache local
      try {
        final docCache = await _db.collection(_col).doc('plans').get();
        if (docCache.exists) {
          final items = _parseItems(docCache.data()?['items']);
          if (items.isNotEmpty) {
            items.sort((a, b) => a.ordre.compareTo(b.ordre));
            debugPrint('[ConfigAbonnementService] ${items.length} plans depuis cache');
            return items;
          }
        }
      } catch (_) {}
      return kPlansParDefaut.map(PlanConfig.fromMap).toList();
    }
  }

  // ── Stream en temps réel ─────────────────────────────────────────────────
  static Stream<List<PlanConfig>> plansStream() {
    return _db.collection(_col).doc('plans').snapshots().map((doc) {
      if (!doc.exists) {
        debugPrint('[ConfigAbonnementService] stream: doc absent');
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }
      final items = _parseItems(doc.data()?['items']);
      if (items.isEmpty) {
        debugPrint('[ConfigAbonnementService] stream: items vide');
        return kPlansParDefaut.map(PlanConfig.fromMap).toList();
      }
      items.sort((a, b) => a.ordre.compareTo(b.ordre));
      debugPrint('[ConfigAbonnementService] stream: ${items.length} plans reçus');
      return items;
    });
  }

  // ── Charger config globale (lecture réseau forcée) ───────────────────────
  static Future<ConfigAbonnementGlobal> chargerGlobal() async {
    try {
      final doc = await _db.collection(_col).doc('global')
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) return const ConfigAbonnementGlobal();
      return ConfigAbonnementGlobal.fromMap(
        Map<String, dynamic>.fromEntries(
          doc.data()!.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        ),
      );
    } catch (e) {
      debugPrint('[ConfigAbonnementService] chargerGlobal error: $e');
      try {
        final docCache = await _db.collection(_col).doc('global').get();
        if (docCache.exists) {
          return ConfigAbonnementGlobal.fromMap(
            Map<String, dynamic>.fromEntries(
              docCache.data()!.entries.map((e) => MapEntry(e.key.toString(), e.value)),
            ),
          );
        }
      } catch (_) {}
      return const ConfigAbonnementGlobal();
    }
  }

  // ── Stream config globale ────────────────────────────────────────────────
  static Stream<ConfigAbonnementGlobal> globalStream() {
    return _db.collection(_col).doc('global').snapshots().map((doc) {
      if (!doc.exists) return const ConfigAbonnementGlobal();
      try {
        return ConfigAbonnementGlobal.fromMap(
          Map<String, dynamic>.fromEntries(
            doc.data()!.entries.map((e) => MapEntry(e.key.toString(), e.value)),
          ),
        );
      } catch (e) {
        debugPrint('[ConfigAbonnementService] globalStream parse ERROR: $e');
        return const ConfigAbonnementGlobal();
      }
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

  // ── Initialiser avec les plans par défaut (UNIQUEMENT si vraiment absent) ─
  // N'est plus appelé automatiquement pour éviter d'écraser les données admin.
  static Future<void> initialiserSiAbsent() async {
    try {
      final doc = await _db.collection(_col).doc('plans')
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) {
        debugPrint('[ConfigAbonnementService] initialisation des plans par défaut');
        await _db.collection(_col).doc('plans').set({
          'items': kPlansParDefaut,
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _db.collection(_col).doc('global').set(
          const ConfigAbonnementGlobal().toMap(),
        );
      }
    } catch (e) {
      debugPrint('[ConfigAbonnementService] initialiserSiAbsent error: $e');
    }
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
