import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
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

      // Si ancienMdp est vide → l'utilisateur vient de se connecter
      // via un lien Firebase (password reset) et est déjà authentifié récemment
      if (ancienMdp.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: ancienMdp,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.updatePassword(nouveauMdp);
      await _db.collection('users').doc(user.uid).update({
        'mot_de_passe_provisoire': false,
        'mdp_temp': FieldValue.delete(),
      });
      if (_utilisateurConnecte != null) {
        _utilisateurConnecte!.motDePasseProvisoire = false;
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Mot de passe actuel incorrect.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Session expirée. Reconnectez-vous et réessayez.';
      }
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

  // ═══════════════════════════════════════
  // MEMBRES — AGENT & CONTRÔLEUR
  // ═══════════════════════════════════════

  /// Ajoute un agent : crée le doc Firestore + envoie un email d'invitation
  /// via Firebase Password Reset. Ne déconnecte PAS le gestionnaire.
  Future<Map<String, String>?> ajouterAgent({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
  }) async {
    return _ajouterMembre(
      nom: nom, prenom: prenom,
      telephone: telephone, email: email,
      role: 'agent',
    );
  }

  Future<Map<String, String>?> ajouterControleur({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
  }) async {
    return _ajouterMembre(
      nom: nom, prenom: prenom,
      telephone: telephone, email: email,
      role: 'controleur',
    );
  }

  Future<Map<String, String>?> _ajouterMembre({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String role,
  }) async {
    if (_utilisateurConnecte == null) return null;

    final emailTrimmed = email.trim();
    final entrepriseId = _utilisateurConnecte!.entrepriseId;
    final gestionnaireId = _utilisateurConnecte!.id;

    try {
      // ── Étape 1 : vérifier si l'email existe déjà dans Firestore ──────────
      final existing = await _db.collection('users')
          .where('email', isEqualTo: emailTrimmed)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'erreur': 'Cet email est déjà associé à un compte.'};
      }

      // ── Étape 2 : créer un UID unique pour ce membre ──────────────────────
      final uid = _uuid.v4();
      final mdpTemp = _genererMdpProvisoire();

      // ── Étape 3 : créer le document Firestore (AVANT la création Auth)  ──
      // On stocke le mdpTemp pour que le membre puisse s'identifier
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': emailTrimmed,
        'role': role,
        'entreprise_id': entrepriseId,
        'gestionnaire_id': gestionnaireId,
        'mot_de_passe_provisoire': true,
        'mdp_temp': mdpTemp,           // stocké temporairement pour l'invitation
        'invitation_envoyee': false,
        'date_creation': Timestamp.now(),
        'actif': true,
      });

      // ── Étape 4 : créer le compte Firebase Auth sans déconnecter  ─────────
      // On utilise une 2ème instance Auth (ou la méthode admin via Firestore)
      // → Ici on utilise le SDK client avec une astuce : créer via REST API
      //   pour ne pas changer la session courante.
      bool compteCreeSansDeconnexion = false;
      try {
        // Tentative via REST API Firebase Auth (ne déconnecte pas)
        compteCreeSansDeconnexion = await _creerCompteViaRestApi(
          uid: uid,
          email: emailTrimmed,
          mdp: mdpTemp,
          displayName: '$prenom $nom',
        );
      } catch (e) {
        debugPrint('REST API échouée, fallback: $e');
      }

      if (!compteCreeSansDeconnexion) {
        // Fallback : stocker les infos pour que le membre s'inscrive lui-même
        // via le lien d'invitation (sans créer de compte Auth maintenant)
        await _db.collection('users').doc(uid).update({
          'invitation_mode': 'self_register',
        });
      } else {
        await _db.collection('users').doc(uid).update({
          'invitation_mode': 'pre_created',
        });
      }

      // ── Étape 5 : envoyer l'email d'invitation ────────────────────────────
      // On utilise sendPasswordResetEmail si le compte existe, sinon
      // on envoie un email de bienvenue avec les infos de connexion temporaires
      bool emailEnvoye = false;
      if (compteCreeSansDeconnexion) {
        try {
          await _auth.sendPasswordResetEmail(
            email: emailTrimmed,
            actionCodeSettings: ActionCodeSettings(
              url: 'https://sikaflow-c8869.web.app/?mode=newmember',
              handleCodeInApp: false,
            ),
          );
          emailEnvoye = true;
          await _db.collection('users').doc(uid).update({
            'invitation_envoyee': true,
          });
        } catch (e) {
          debugPrint('Erreur envoi email reset: $e');
        }
      }

      // ── Étape 6 : rafraîchir la liste ────────────────────────────────────
      await _chargerTousLesUtilisateurs();

      return {
        'id': uid,
        'email': emailTrimmed,
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'role': role,
        'mdp_temp': mdpTemp,
        'email_envoye': emailEnvoye ? 'true' : 'false',
      };
    } catch (e) {
      debugPrint('Erreur ajout membre ($role): $e');
      return {'erreur': 'Erreur inattendue : $e'};
    }
  }

  /// Crée un compte Firebase Auth via la REST API (sans changer la session)
  Future<bool> _creerCompteViaRestApi({
    required String uid,
    required String email,
    required String mdp,
    required String displayName,
  }) async {
    // Clé API Web Firebase (depuis firebase_options.dart)
    const apiKey = 'AIzaSyApGdz7u5i10Fytoz6hcej63rVTKeH9Ivg';
    const url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': mdp,
          'displayName': displayName,
          'returnSecureToken': false,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Compte créé via REST API pour $email');
        return true;
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? 'Inconnu';
        debugPrint('REST signUp erreur ($errorMessage) pour $email');
        // EMAIL_EXISTS est aussi une réussite (compte déjà là)
        if (errorMessage == 'EMAIL_EXISTS') return true;
        return false;
      }
    } catch (e) {
      debugPrint('REST signUp exception: $e');
      return false;
    }
  }

  /// Charge tous les utilisateurs de l'entreprise depuis Firestore
  Future<void> _chargerTousLesUtilisateurs() async {
    try {
      final entrepriseId = _utilisateurConnecte?.entrepriseId;
      if (entrepriseId == null) return;

      final snapshot = await _db
          .collection('users')
          .where('entreprise_id', isEqualTo: entrepriseId)
          .get();

      _tousLesUtilisateurs = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
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
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
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
