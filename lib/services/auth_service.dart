import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Utilisateur courant Firebase ───────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Inscription gestionnaire + création entreprise ─────────────────────
  Future<Map<String, dynamic>> inscrireGestionnaire({
    required String email,
    required String motDePasse,
    required String prenom,
    required String nom,
    required String telephone,
    required String nomEntreprise,
    required double capitalDepart,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final uid = credential.user!.uid;

      // 2. Créer l'entreprise dans Firestore
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
        'statut': 'essai', // essai | actif | suspendu | expire
        'plan': 'essai_gratuit',
        'date_debut_essai': Timestamp.fromDate(maintenant),
        'date_fin_essai': Timestamp.fromDate(finEssai),
        'date_expiration_abonnement': Timestamp.fromDate(finEssai),
        'abonnements': [],
      });

      // 3. Créer le profil utilisateur
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': 'gestionnaire',
        'entreprise_id': entrepriseId,
        'mot_de_passe_provisoire': false,
        'date_creation': Timestamp.fromDate(maintenant),
        'actif': true,
      });

      return {'success': true, 'entreprise_id': entrepriseId, 'user_id': uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreurAuth(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur inattendue: $e'};
    }
  }

  // ─── Connexion ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);
      final uid = _auth.currentUser!.uid;

      // Récupérer le profil Firestore
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return {'success': false, 'erreur': 'Profil utilisateur introuvable.'};
      }

      final data = userDoc.data()!;
      return {
        'success': true,
        'role': data['role'],
        'mot_de_passe_provisoire': data['mot_de_passe_provisoire'] ?? false,
        'entreprise_id': data['entreprise_id'],
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreurAuth(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur de connexion: $e'};
    }
  }

  // ─── Déconnexion ─────────────────────────────────────────────────────────
  Future<void> deconnecter() async {
    await _auth.signOut();
  }

  // ─── Changer le mot de passe ─────────────────────────────────────────────
  Future<Map<String, dynamic>> changerMotDePasse({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: ancienMotDePasse,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(nouveauMotDePasse);

      // Marquer comme non-provisoire
      await _db.collection('users').doc(user.uid).update({
        'mot_de_passe_provisoire': false,
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreurAuth(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ─── Ajouter un membre (agent/contrôleur) ────────────────────────────────
  Future<Map<String, dynamic>> ajouterMembre({
    required String email,
    required String prenom,
    required String nom,
    required String telephone,
    required String role, // 'agent' | 'controleur'
    required String entrepriseId,
    required String motDePasseProvisoire,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasseProvisoire,
      );
      final uid = credential.user!.uid;

      // Créer le profil Firestore
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': role,
        'entreprise_id': entrepriseId,
        'mot_de_passe_provisoire': true,
        'code_provisoire': motDePasseProvisoire,
        'date_creation': Timestamp.now(),
        'actif': true,
        'controleur_id': null,
      });

      // Se reconnecter avec le gestionnaire (Firebase déconnecte lors de createUser)
      // Note: Cette action nécessite une re-authentification côté client
      return {'success': true, 'user_id': uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreurAuth(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ─── Récupérer profil utilisateur ────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfilUtilisateur(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ─── Traduction erreurs Firebase Auth ────────────────────────────────────
  String _traduireErreurAuth(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères).';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-not-found':
        return 'Aucun compte avec cet identifiant.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Identifiant ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      default:
        return 'Erreur d\'authentification ($code).';
    }
  }
}
