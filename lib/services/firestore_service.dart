import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════
  // ENTREPRISES
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getEntreprise(String entrepriseId) async {
    final doc = await _db.collection('entreprises').doc(entrepriseId).get();
    return doc.exists ? {...doc.data()!, 'id': doc.id} : null;
  }

  Stream<DocumentSnapshot> entrepriseStream(String entrepriseId) {
    return _db.collection('entreprises').doc(entrepriseId).snapshots();
  }

  Future<void> updateEntreprise(String entrepriseId, Map<String, dynamic> data) async {
    await _db.collection('entreprises').doc(entrepriseId).update(data);
  }

  // ═══════════════════════════════════════════════════════
  // UTILISATEURS / MEMBRES
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? {...doc.data()!, 'id': doc.id} : null;
  }

  Stream<QuerySnapshot> membresEntrepriseStream(String entrepriseId) {
    return _db
        .collection('users')
        .where('entreprise_id', isEqualTo: entrepriseId)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getMembresParRole(
      String entrepriseId, String role) async {
    final snap = await _db
        .collection('users')
        .where('entreprise_id', isEqualTo: entrepriseId)
        .where('role', isEqualTo: role)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<void> assignerAgentAuControleur(
      String agentId, String controleurId) async {
    await _db.collection('users').doc(agentId).update({
      'controleur_id': controleurId,
    });
  }

  Future<void> desassignerAgent(String agentId) async {
    await _db.collection('users').doc(agentId).update({
      'controleur_id': null,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> suspendreUtilisateur(String uid, bool actif) async {
    await _db.collection('users').doc(uid).update({'actif': actif});
  }

  // ═══════════════════════════════════════════════════════
  // POINTS JOURNALIERS
  // ═══════════════════════════════════════════════════════

  Future<String> ajouterPointJournalier({
    required String entrepriseId,
    required String agentId,
    required DateTime date,
    required double especes,
    required double mtnSim,
    required double moovSim,
    required double celtisSim,
    String? notes,
  }) async {
    final ref = _db.collection('points_journaliers').doc();
    final total = especes + mtnSim + moovSim + celtisSim;
    await ref.set({
      'id': ref.id,
      'entreprise_id': entrepriseId,
      'agent_id': agentId,
      'date': Timestamp.fromDate(date),
      'especes': especes,
      'mtn_sim': mtnSim,
      'moov_sim': moovSim,
      'celtiis_sim': celtisSim,
      'total': total,
      'notes': notes ?? '',
      'valide': false,
      'valide_par': null,
      'date_validation': null,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> validerPoint(String pointId, String controleurId) async {
    await _db.collection('points_journaliers').doc(pointId).update({
      'valide': true,
      'valide_par': controleurId,
      'date_validation': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> pointsAgentStream(String agentId, {int limite = 30}) {
    return _db
        .collection('points_journaliers')
        .where('agent_id', isEqualTo: agentId)
        .orderBy('date', descending: true)
        .limit(limite)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getPointsEntreprise(
      String entrepriseId, DateTime debut, DateTime fin) async {
    final snap = await _db
        .collection('points_journaliers')
        .where('entreprise_id', isEqualTo: entrepriseId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getPointsAgent(
      String agentId, DateTime debut, DateTime fin) async {
    final snap = await _db
        .collection('points_journaliers')
        .where('agent_id', isEqualTo: agentId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['date'] as Timestamp).toDate();
      final db = (b['date'] as Timestamp).toDate();
      return db.compareTo(da);
    });
    return docs;
  }

  // ═══════════════════════════════════════════════════════
  // RISTOURNES
  // ═══════════════════════════════════════════════════════

  Future<String> ajouterRistourne({
    required String entrepriseId,
    required String agentId,
    required String controleurId,
    required String operateur, // 'mtn' | 'moov' | 'celtiis'
    required double montant,
    required DateTime date,
    String? notes,
  }) async {
    final ref = _db.collection('ristournes').doc();
    await ref.set({
      'id': ref.id,
      'entreprise_id': entrepriseId,
      'agent_id': agentId,
      'controleur_id': controleurId,
      'operateur': operateur,
      'montant': montant,
      'date': Timestamp.fromDate(date),
      'notes': notes ?? '',
      'retiree': false,
      'date_retrait': null,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> marquerRistourneRetiree(String ristourneId) async {
    await _db.collection('ristournes').doc(ristourneId).update({
      'retiree': true,
      'date_retrait': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getRistournesAgent(String agentId) async {
    final snap = await _db
        .collection('ristournes')
        .where('agent_id', isEqualTo: agentId)
        .get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['date'] as Timestamp).toDate();
      final db = (b['date'] as Timestamp).toDate();
      return db.compareTo(da);
    });
    return docs;
  }

  Future<List<Map<String, dynamic>>> getRistournesEntreprise(
      String entrepriseId) async {
    final snap = await _db
        .collection('ristournes')
        .where('entreprise_id', isEqualTo: entrepriseId)
        .get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['date'] as Timestamp).toDate();
      final db = (b['date'] as Timestamp).toDate();
      return db.compareTo(da);
    });
    return docs;
  }

  // ═══════════════════════════════════════════════════════
  // RETRAITS
  // ═══════════════════════════════════════════════════════

  Future<String> ajouterRetrait({
    required String entrepriseId,
    required String gestionnaireId,
    required String agentId,
    required String type, // 'especes' | 'ristourne'
    required double montant,
    required String operateur,
    String? notes,
  }) async {
    final ref = _db.collection('retraits').doc();
    await ref.set({
      'id': ref.id,
      'entreprise_id': entrepriseId,
      'gestionnaire_id': gestionnaireId,
      'agent_id': agentId,
      'type': type,
      'montant': montant,
      'operateur': operateur,
      'notes': notes ?? '',
      'date': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getRetraitsEntreprise(
      String entrepriseId, {int limite = 50}) async {
    final snap = await _db
        .collection('retraits')
        .where('entreprise_id', isEqualTo: entrepriseId)
        .limit(limite)
        .get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final db = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return db.compareTo(da);
    });
    return docs;
  }

  // ═══════════════════════════════════════════════════════
  // ABONNEMENTS
  // ═══════════════════════════════════════════════════════

  Future<void> activerAbonnement({
    required String entrepriseId,
    required String type, // 'semestriel' | 'mensuel' | 'annuel'
    required int dureeMois,
    required double montant,
    required String modePaiement, // 'fedapay' | 'manuel' | 'mtn' | 'moov' | 'carte'
    String? transactionId,
    String? adminId,
    String? planCode,
  }) async {
    final now = DateTime.now();
    // Récupérer la date d'expiration actuelle
    final entreprise = await getEntreprise(entrepriseId);
    DateTime baseDate = now;
    if (entreprise != null) {
      final expiration = (entreprise['date_expiration_abonnement'] as Timestamp?)?.toDate();
      if (expiration != null && expiration.isAfter(now)) {
        baseDate = expiration; // prolonger depuis la fin actuelle
      }
    }
    final nouvellExpiration = DateTime(
        baseDate.year, baseDate.month + dureeMois, baseDate.day);

    // Enregistrer l'abonnement
    final abonnementRef = _db.collection('abonnements').doc();
    await abonnementRef.set({
      'id': abonnementRef.id,
      'entreprise_id': entrepriseId,
      'type': type,
      'duree_mois': dureeMois,
      'montant': montant,
      'mode_paiement': modePaiement,
      'transaction_id': transactionId,
      'admin_id': adminId,
      'plan': planCode,
      'date_debut': Timestamp.fromDate(now),
      'date_fin': Timestamp.fromDate(nouvellExpiration),
      'created_at': FieldValue.serverTimestamp(),
    });

    // Mettre à jour l'entreprise
    await updateEntreprise(entrepriseId, {
      'statut': 'actif',
      'plan': 'semestriel',
      'date_expiration_abonnement': Timestamp.fromDate(nouvellExpiration),
    });
  }

  // ═══════════════════════════════════════════════════════
  // SUPER ADMIN
  // ═══════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllEntreprises() async {
    final snap = await _db.collection('entreprises').get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['date_creation'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final db = (b['date_creation'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return db.compareTo(da);
    });
    return docs;
  }

  Stream<QuerySnapshot> allEntreprisesStream() {
    return _db.collection('entreprises').snapshots();
  }

  Future<void> changerStatutEntreprise(String entrepriseId, String statut) async {
    await updateEntreprise(entrepriseId, {'statut': statut});
  }

  Future<List<Map<String, dynamic>>> getAllAbonnements() async {
    final snap = await _db.collection('abonnements').get();
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final da = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final db = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return db.compareTo(da);
    });
    return docs;
  }

  // Stats globales pour le super admin
  Future<Map<String, dynamic>> getStatsGlobales() async {
    final entreprisesSnap = await _db.collection('entreprises').get();
    final abonnementsSnap = await _db.collection('abonnements').get();
    final usersSnap = await _db.collection('users').get();

    int actives = 0, essai = 0, suspendues = 0, expirees = 0;
    double revenusTotal = 0;
    final now = DateTime.now();

    for (final doc in entreprisesSnap.docs) {
      final data = doc.data();
      final statut = data['statut'] ?? 'essai';
      final expiration = (data['date_expiration_abonnement'] as Timestamp?)?.toDate();
      if (statut == 'actif') {
        if (expiration != null && expiration.isBefore(now)) {
          expirees++;
        } else {
          actives++;
        }
      } else if (statut == 'essai') {
        essai++;
      } else if (statut == 'suspendu') {
        suspendues++;
      }
    }

    for (final doc in abonnementsSnap.docs) {
      final data = doc.data();
      revenusTotal += (data['montant'] as num?)?.toDouble() ?? 0;
    }

    return {
      'total_entreprises': entreprisesSnap.docs.length,
      'actives': actives,
      'essai': essai,
      'suspendues': suspendues,
      'expirees': expirees,
      'total_utilisateurs': usersSnap.docs.length,
      'total_abonnements': abonnementsSnap.docs.length,
      'revenus_total': revenusTotal,
    };
  }
}
