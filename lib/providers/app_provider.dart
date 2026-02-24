import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/point_journalier.dart';
import '../models/ristourne.dart';
import '../models/retrait.dart';
import '../models/entreprise_model.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  UserModel? _utilisateurConnecte;
  EntrepriseModel? _entrepriseActive;
  List<UserModel> _tousLesUtilisateurs = [];
  List<EntrepriseModel> _entreprises = [];
  List<PointJournalier> _pointsJournaliers = [];
  List<Ristourne> _ristournes = [];
  List<Retrait> _retraits = [];
  bool _chargement = false;
  String? _erreur;

  UserModel? get utilisateurConnecte => _utilisateurConnecte;
  EntrepriseModel? get entrepriseActive => _entrepriseActive;
  List<UserModel> get tousLesUtilisateurs => _tousLesUtilisateurs;
  List<EntrepriseModel> get entreprises => _entreprises;
  List<PointJournalier> get pointsJournaliers => _pointsJournaliers;
  List<Ristourne> get ristournes => _ristournes;
  List<Retrait> get retraits => _retraits;
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  bool get estConnecte => _utilisateurConnecte != null;
  bool get aucuneEntrepriseExiste => false;

  // ═══════════════════════════════════════
  // INITIALISATION — écoute Firebase Auth
  // ═══════════════════════════════════════
  Future<void> initialiser() async {
    _setChargement(true);

    // Timeout de sécurité : si Firebase ne répond pas en 8 secondes,
    // on débloquer l'app et affiche la landing page
    Future.delayed(const Duration(seconds: 8), () {
      if (_chargement) {
        debugPrint('Firebase Auth timeout — affichage landing page');
        _chargement = false;
        notifyListeners();
      }
    });

    try {
      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _utilisateurConnecte = null;
          _entrepriseActive = null;
          _chargement = false;
          notifyListeners();
        } else {
          await _chargerProfilFirebase(firebaseUser.uid);
        }
      });
    } catch (e) {
      debugPrint('authStateChanges error: $e');
      _chargement = false;
      notifyListeners();
    }
  }

  Future<void> _chargerProfilFirebase(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        _utilisateurConnecte = null;
        _setChargement(false);
        notifyListeners();
        return;
      }

      final data = userDoc.data()!;
      _utilisateurConnecte = UserModel(
        id: uid,
        nom: (data['nom'] ?? '') as String,
        prenom: (data['prenom'] ?? '') as String,
        telephone: (data['telephone'] ?? '') as String,
        email: data['email'] as String?,
        motDePasse: '',
        role: (data['role'] ?? 'agent') as String,
        entrepriseId: data['entreprise_id'] as String?,
        dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        motDePasseProvisoire: (data['mot_de_passe_provisoire'] ?? false) as bool,
        actif: (data['actif'] ?? true) as bool,
      );

      if (_utilisateurConnecte!.entrepriseId != null) {
        await _chargerEntreprise(_utilisateurConnecte!.entrepriseId!);
      }

      _chargerDonneesLocales();
      _setChargement(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      _utilisateurConnecte = null;
      _setChargement(false);
      notifyListeners();
    }
  }

  Future<void> _chargerEntreprise(String entrepriseId) async {
    try {
      final doc = await _db.collection('entreprises').doc(entrepriseId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _entrepriseActive = EntrepriseModel(
          id: entrepriseId,
          nom: (data['nom'] ?? '') as String,
          capitalDepart: ((data['capital_depart'] ?? 0) as num).toDouble(),
          gestionnaireId: (data['gestionnaire_id'] ?? '') as String,
          dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Erreur chargement entreprise: $e');
    }
  }

  void _chargerDonneesLocales() {
    try {
      if (Hive.isBoxOpen('points')) {
        _pointsJournaliers = Hive.box<PointJournalier>('points').values.toList();
      }
      if (Hive.isBoxOpen('ristournes')) {
        _ristournes = Hive.box<Ristourne>('ristournes').values.toList();
      }
      if (Hive.isBoxOpen('retraits')) {
        _retraits = Hive.box<Retrait>('retraits').values.toList();
      }
    } catch (e) {
      debugPrint('Hive local: $e');
    }
  }

  // ═══════════════════════════════════════
  // CONNEXION FIREBASE AUTH
  // ═══════════════════════════════════════
  Future<bool> seConnecter(String identifiant, String motDePasse) async {
    _setChargement(true);
    _erreur = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: identifiant.trim(),
        password: motDePasse,
      );
      // Charger directement le profil sans attendre authStateChanges
      // pour que la navigation soit immédiate
      if (credential.user != null) {
        await _chargerProfilFirebase(credential.user!.uid);
      }
      return _utilisateurConnecte != null;
    } on FirebaseAuthException catch (e) {
      _erreur = _traduireErreur(e.code);
      _setChargement(false);
      notifyListeners();
      return false;
    } catch (e) {
      _erreur = 'Erreur: $e';
      _setChargement(false);
      notifyListeners();
      return false;
    }
  }

  String _traduireErreur(String code) {
    switch (code) {
      case 'user-not-found': return 'Aucun compte avec cet identifiant.';
      case 'wrong-password': return 'Mot de passe incorrect.';
      case 'invalid-credential': return 'Email ou mot de passe incorrect.';
      case 'too-many-requests': return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed': return 'Pas de connexion internet.';
      default: return 'Erreur ($code).';
    }
  }

  void seDeconnecter() {
    _auth.signOut();
    _utilisateurConnecte = null;
    _entrepriseActive = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════
  // INSCRIPTION GESTIONNAIRE
  // ═══════════════════════════════════════
  /// [uidExistant] : UID du compte Firebase déjà créé lors de la vérification email.
  /// Si fourni, on ne recrée PAS le compte Firebase Auth — on crée seulement les
  /// documents Firestore (entreprise + user). 
  Future<String?> inscrireGestionnaire({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String motDePasse,
    required String nomEntreprise,
    required double capitalDepart,
    String? descriptionEntreprise,
    String? uidExistant,        // ← nouveau paramètre
  }) async {
    try {
      String uid;

      if (uidExistant != null && uidExistant.isNotEmpty) {
        // Compte déjà créé lors de la vérification email — utiliser l'UID existant
        uid = uidExistant;
      } else {
        // Flux sans vérification préalable : créer le compte normalement
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: motDePasse,
        );
        uid = credential.user!.uid;
      }

      final entrepriseRef = _db.collection('entreprises').doc();
      final entrepriseId = entrepriseRef.id;
      final maintenant = DateTime.now();
      final finEssai = maintenant.add(const Duration(days: 30));

      await entrepriseRef.set({
        'id': entrepriseId,
        'nom': nomEntreprise,
        'capital_depart': capitalDepart,
        'solde_actuel': capitalDepart,
        'gestionnaire_id': uid,
        'date_creation': Timestamp.fromDate(maintenant),
        'statut': 'essai',
        'plan': 'essai_gratuit',
        'date_fin_essai': Timestamp.fromDate(finEssai),
        'date_expiration_abonnement': Timestamp.fromDate(finEssai),
      });

      await _db.collection('users').doc(uid).set({
        'id': uid,
        'prenom': prenom,
        'nom': nom,
        'email': email.trim(),
        'telephone': telephone,
        'role': 'gestionnaire',
        'entreprise_id': entrepriseId,
        'mot_de_passe_provisoire': false,
        'date_creation': Timestamp.fromDate(maintenant),
        'actif': true,
      });

      // ✅ Charger immédiatement le profil dans le provider
      // pour que AppRouter redirige vers le dashboard
      await _chargerProfilFirebase(uid);

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use': return 'Cet email est déjà utilisé.';
        case 'weak-password': return 'Mot de passe trop faible (min. 6 caractères).';
        case 'invalid-email': return 'Email invalide.';
        default: return 'Erreur: ${e.message}';
      }
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  // ═══════════════════════════════════════
  // CHANGEMENT MOT DE PASSE
  // ═══════════════════════════════════════
  Future<String?> changerMotDePasse({
    required String ancienMdp,
    required String nouveauMdp,
  }) async {
    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: ancienMdp,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(nouveauMdp);
      await _db.collection('users').doc(user.uid).update({
        'mot_de_passe_provisoire': false,
      });
      if (_utilisateurConnecte != null) {
        _utilisateurConnecte!.motDePasseProvisoire = false;
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'Mot de passe actuel incorrect.';
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  // ═══════════════════════════════════════
  // MEMBRES
  // ═══════════════════════════════════════
  String _genererMdpProvisoire() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int val = rnd;
    for (int i = 0; i < 6; i++) {
      code += chars[val % chars.length];
      val = (val ~/ chars.length) + i * 7;
    }
    return code;
  }

  Future<Map<String, String>?> ajouterAgent({
    required String nom,
    required String prenom,
    required String identifiant,
    required bool estEmail,
  }) async {
    if (_utilisateurConnecte == null) return null;
    final mdpProvisoire = _genererMdpProvisoire();
    try {
      final email = estEmail ? identifiant : '$identifiant@sikaflow.app';
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: mdpProvisoire,
      );
      final uid = credential.user!.uid;
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'nom': nom,
        'prenom': prenom,
        'telephone': estEmail ? '' : identifiant,
        'email': email,
        'role': 'agent',
        'entreprise_id': _utilisateurConnecte!.entrepriseId,
        'mot_de_passe_provisoire': true,
        'date_creation': Timestamp.now(),
        'actif': true,
      });
      return {'id': uid, 'mdpProvisoire': mdpProvisoire};
    } catch (e) {
      debugPrint('Erreur ajout agent: $e');
      return null;
    }
  }

  Future<Map<String, String>?> ajouterControleur({
    required String nom,
    required String prenom,
    required String identifiant,
    required bool estEmail,
  }) async {
    if (_utilisateurConnecte == null) return null;
    final mdpProvisoire = _genererMdpProvisoire();
    try {
      final email = estEmail ? identifiant : '$identifiant@sikaflow.app';
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: mdpProvisoire,
      );
      final uid = credential.user!.uid;
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'nom': nom,
        'prenom': prenom,
        'telephone': estEmail ? '' : identifiant,
        'email': email,
        'role': 'controleur',
        'entreprise_id': _utilisateurConnecte!.entrepriseId,
        'mot_de_passe_provisoire': true,
        'date_creation': Timestamp.now(),
        'actif': true,
      });
      return {'id': uid, 'mdpProvisoire': mdpProvisoire};
    } catch (e) {
      debugPrint('Erreur ajout contrôleur: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════
  // GETTERS FILTRÉS
  // ═══════════════════════════════════════
  List<UserModel> get mesAgents => _tousLesUtilisateurs
      .where((u) => u.role == 'agent' && u.entrepriseId == _utilisateurConnecte?.entrepriseId)
      .toList();

  List<UserModel> get mesControleurs => _tousLesUtilisateurs
      .where((u) => u.role == 'controleur' && u.entrepriseId == _utilisateurConnecte?.entrepriseId)
      .toList();

  List<UserModel> agentsDuControleur(String controleurId) => mesAgents;
  List<UserModel> agentsNonAssignes() => mesAgents;

  List<PointJournalier> get mesPointsJournaliers {
    if (_utilisateurConnecte == null) return [];
    return _pointsJournaliers
        .where((p) =>
            p.agentId == _utilisateurConnecte!.id ||
            p.gestionnaireId == _utilisateurConnecte!.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  PointJournalier? getPointDuJour(String agentId) {
    final auj = DateTime.now();
    try {
      return _pointsJournaliers.firstWhere(
        (p) =>
            p.agentId == agentId &&
            p.date.day == auj.day &&
            p.date.month == auj.month &&
            p.date.year == auj.year,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> sauvegarderPoint(PointJournalier point) async {
    try {
      if (Hive.isBoxOpen('points')) {
        await Hive.box<PointJournalier>('points').put(point.id, point);
        _pointsJournaliers = Hive.box<PointJournalier>('points').values.toList();
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde point: $e');
    }
    notifyListeners();
  }

  Map<String, double> get syntheseAujourdhui {
    return {'especes': 0, 'mtn': 0, 'moov': 0, 'celtiis': 0, 'total': 0};
  }

  List<Map<String, dynamic>> getDonneesEvolution(String periode) {
    final maintenant = DateTime.now();
    List<Map<String, dynamic>> result = [];
    if (periode == 'semaine') {
      for (int i = 6; i >= 0; i--) {
        final date = maintenant.subtract(Duration(days: i));
        result.add({'label': _jourCourt(date.weekday), 'valeur': 0.0, 'date': date});
      }
    } else {
      for (int m = 1; m <= 12; m++) {
        result.add({'label': _moisCourt(m), 'valeur': 0.0, 'date': DateTime(maintenant.year, m)});
      }
    }
    return result;
  }

  String _jourCourt(int w) => ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][w - 1];
  String _moisCourt(int m) =>
      ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'][m - 1];

  List<Ristourne> get mesRistournes => _ristournes;
  List<Ristourne> get ristournesDisponibles => _ristournes.where((r) => !r.retiree).toList();
  double get totalRistournesDisponibles => ristournesDisponibles.fold(0.0, (s, r) => s + r.montant);

  Future<void> ajouterRistourne(Ristourne ristourne) async {
    try {
      if (Hive.isBoxOpen('ristournes')) {
        await Hive.box<Ristourne>('ristournes').put(ristourne.id, ristourne);
        _ristournes = Hive.box<Ristourne>('ristournes').values.toList();
      }
    } catch (e) {
      debugPrint('Erreur ajout ristourne: $e');
    }
    notifyListeners();
  }

  List<Retrait> get mesRetraits => _retraits;

  Future<void> effectuerRetrait(Retrait retrait) async {
    try {
      if (Hive.isBoxOpen('retraits')) {
        await Hive.box<Retrait>('retraits').put(retrait.id, retrait);
        _retraits = Hive.box<Retrait>('retraits').values.toList();
      }
    } catch (e) {
      debugPrint('Erreur retrait: $e');
    }
    notifyListeners();
  }

  Future<void> assignerAgentAControleur({
    required String agentId,
    required String controleurId,
  }) async => notifyListeners();

  Future<void> desassignerAgentDeControleur({
    required String agentId,
    required String controleurId,
  }) async => notifyListeners();

  void _setChargement(bool val) {
    _chargement = val;
    notifyListeners();
  }

  String genererNouvelId() => _uuid.v4();

  UserModel? getUtilisateurParId(String id) {
    try {
      return _tousLesUtilisateurs.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  String formaterMontant(double montant) {
    if (montant >= 1000000) return '${(montant / 1000000).toStringAsFixed(1)} M FCFA';
    if (montant >= 1000) return '${(montant / 1000).toStringAsFixed(0)} K FCFA';
    return '${montant.toStringAsFixed(0)} FCFA';
  }
}
