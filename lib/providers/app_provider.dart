import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/entreprise_model.dart';
import '../models/stand_model.dart';
import '../models/operation_model.dart';
import '../models/abonnement_model.dart';

class AppProvider extends ChangeNotifier {
  // ignore: unused_field
  final _uuid = const Uuid();
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // ── État global ───────────────────────────────────────────────────────────
  UserModel?       _utilisateurConnecte;
  EntrepriseModel? _entrepriseActive;
  StandModel?      _standActuel; // stand de l'agent connecté
  bool   _chargement = false;
  String? _erreur;

  // ── Listes ────────────────────────────────────────────────────────────────
  List<UserModel>           _membres         = [];
  List<StandModel>          _stands          = [];
  List<OperationModel>      _operations      = [];
  List<TauxRistourne>       _tauxRistourne   = [];
  List<AlerteModel>         _alertes         = [];
  List<DemandeReequilibrage> _demandesReequil = [];
  List<AbonnementModel>     _abonnements     = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel?       get utilisateurConnecte  => _utilisateurConnecte;
  EntrepriseModel? get entrepriseActive     => _entrepriseActive;
  StandModel?      get standActuel          => _standActuel;
  bool             get chargement           => _chargement;
  bool             get estConnecte          => _utilisateurConnecte != null;
  String?          get erreur               => _erreur;
  // Retourne true si l'email Firebase est v\u00e9rifi\u00e9
  bool             get emailVerifie         => _auth.currentUser?.emailVerified ?? false;

  List<UserModel>            get membres          => List.unmodifiable(_membres);
  List<StandModel>           get stands           => List.unmodifiable(_stands);
  List<OperationModel>       get operations       => List.unmodifiable(_operations);
  List<TauxRistourne>        get tauxRistourne    => List.unmodifiable(_tauxRistourne);
  List<AlerteModel>          get alertes          => List.unmodifiable(_alertes);
  List<AlerteModel>          get alertesNonLues   => _alertes.where((a) => !a.lue).toList();
  List<DemandeReequilibrage> get demandesReequil  => List.unmodifiable(_demandesReequil);
  List<DemandeReequilibrage> get demandesEnAttente =>
      _demandesReequil.where((d) => d.estEnAttente).toList();
  List<AbonnementModel>      get abonnements      => List.unmodifiable(_abonnements);

  List<UserModel> get agents      => _membres.where((u) => u.role == 'agent').toList();
  List<UserModel> get controleurs => _membres.where((u) => u.role == 'controleur').toList();
  List<StandModel> get standsActifs => _stands.where((s) => s.actif).toList();

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> initialiser() async {
    _setChargement(true);

    try {
      // Attendre le premier événement Firebase Auth (max 4 secondes)
      final completer = Completer<User?>();

      final sub = _auth.authStateChanges().listen((user) {
        if (!completer.isCompleted) completer.complete(user);
      }, onError: (e) {
        if (!completer.isCompleted) completer.complete(null);
      });

      // Timeout 4 secondes
      final firebaseUser = await completer.future
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      await sub.cancel();

      if (firebaseUser == null) {
        _viderEtat();
      } else {
        await _chargerProfilFirebase(firebaseUser.uid);
        // Continuer à écouter les changements d'auth
        _auth.authStateChanges().listen((User? u) async {
          if (u == null) {
            _viderEtat();
          } else if (u.uid != _utilisateurConnecte?.id) {
            await _chargerProfilFirebase(u.uid);
          }
        });
      }
    } catch (e) {
      debugPrint('initialiser error: $e');
      _chargement = false;
      notifyListeners();
    }
  }

  void _viderEtat() {
    _utilisateurConnecte = null;
    _entrepriseActive    = null;
    _standActuel         = null;
    _membres             = [];
    _stands              = [];
    _operations          = [];
    _tauxRistourne       = [];
    _alertes             = [];
    _demandesReequil     = [];
    _abonnements         = [];
    _chargement          = false;
    notifyListeners();
  }

  Future<void> _chargerProfilFirebase(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        _viderEtat();
        return;
      }

      _utilisateurConnecte = UserModel.fromFirestore(userDoc.data()!, uid);

      // Charger les données selon le rôle
      if (_utilisateurConnecte!.entrepriseId != null) {
        await _chargerEntreprise(_utilisateurConnecte!.entrepriseId!);
        await Future.wait([
          _chargerMembres(),
          _chargerStands(),
          _chargerTauxRistourne(),
          _chargerAlertes(),
          _chargerDemandesReequilibrage(),
        ]);

        // Si agent : charger son stand
        if (_utilisateurConnecte!.estAgent &&
            _utilisateurConnecte!.standId != null) {
          _standActuel = _stands.firstWhere(
            (s) => s.id == _utilisateurConnecte!.standId,
            orElse: () => _stands.first,
          );
        }
      }

      _setChargement(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      _utilisateurConnecte = null;
      _setChargement(false);
      notifyListeners();
    }
  }

  // ── Connexion / Déconnexion ────────────────────────────────────────────────
  Future<bool> seConnecter(String email, String motDePasse) async {
    _setChargement(true);
    _erreur = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: motDePasse,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _erreur = 'Connexion échouée';
        _setChargement(false);
        notifyListeners();
        return false;
      }

      // Recharger pour avoir le statut emailVerified à jour
      await firebaseUser.reload();
      final userActuel = _auth.currentUser;

      // Si l'email est vérifié → activer le compte si encore en_attente
      if (userActuel != null && userActuel.emailVerified) {
        await _activerCompteApresVerification(firebaseUser.uid);
      }
      // Sinon on laisse passer : la bannière dans le dashboard informera l'utilisateur

      await _chargerProfilFirebase(firebaseUser.uid);
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

  // Activer le compte après vérification email (statut en_attente → essai)
  Future<void> _activerCompteApresVerification(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return;
      final data = userDoc.data()!;

      // Mettre à jour email_verifie dans users
      if (data['email_verifie'] != true) {
        await _db.collection('users').doc(uid).update({'email_verifie': true});
      }

      // Activer l'entreprise si encore en_attente
      final entrepriseId = data['entreprise_id'] as String?;
      if (entrepriseId != null) {
        final entDoc = await _db.collection('entreprises').doc(entrepriseId).get();
        if (entDoc.exists && entDoc.data()?['statut'] == 'en_attente') {
          await _db.collection('entreprises').doc(entrepriseId).update({
            'statut': 'essai',
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur activation compte: $e');
    }
  }

  void seDeconnecter() {
    _auth.signOut();
    _viderEtat();
  }

  // ── Réinitialisation mot de passe ─────────────────────────────────────────
  Future<Map<String, dynamic>> reinitialiserMotDePasse({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreur(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur inattendue: $e'};
    }
  }

  // ── Renvoyer email de vérification ────────────────────────────────────────
  Future<Map<String, dynamic>> renvoyerEmailVerification({
    required String email,
    required String motDePasse,
  }) async {
    try {
      // Se connecter temporairement pour pouvoir envoyer l'email
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: motDePasse,
      );
      await cred.user?.sendEmailVerification();
      await _auth.signOut();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreur(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Renvoyer email de vérification (utilisateur déjà connecté) ───────────
  Future<Map<String, dynamic>> renvoyerEmailVerificationConnecte() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'success': false, 'erreur': 'Utilisateur non connecté'};
      await user.sendEmailVerification();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreur(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Vérifier et activer si email vérifié (appelé depuis le dashboard) ─────
  Future<bool> verifierActivationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      final reloaded = _auth.currentUser;
      if (reloaded != null && reloaded.emailVerified) {
        await _activerCompteApresVerification(reloaded.uid);
        // Mettre à jour le profil local
        if (_utilisateurConnecte != null) {
          final doc = await _db.collection('users').doc(reloaded.uid).get();
          if (doc.exists) {
            _utilisateurConnecte = UserModel.fromFirestore(doc.data()!, reloaded.uid);
          }
          if (_entrepriseActive != null) {
            await _chargerEntreprise(_entrepriseActive!.id);
          }
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur vérification activation: $e');
      return false;
    }
  }

  // ── Inscription gestionnaire ──────────────────────────────────────────────
  Future<Map<String, dynamic>> inscrireGestionnaire({
    required String email,
    required String motDePasse,
    required String prenom,
    required String nom,
    required String telephone,
    required String nomEntreprise,
    String? description,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: motDePasse,
      );
      final uid  = credential.user!.uid;
      final now  = DateTime.now();
      final finEssai         = now.add(const Duration(days: 30));
      final limiteActivation = now.add(const Duration(hours: 72));

      // Envoyer l'email de vérification
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {}

      // Créer l'entreprise avec statut en_attente
      final entrepriseRef = _db.collection('entreprises').doc();
      final entrepriseId  = entrepriseRef.id;
      await entrepriseRef.set({
        'id': entrepriseId,
        'nom': nomEntreprise,
        'description': description ?? '',
        'gestionnaire_id': uid,
        'date_creation': Timestamp.fromDate(now),
        'statut': 'en_attente',          // actif après vérification email
        'plan': 'essai_gratuit',
        'date_fin_essai': Timestamp.fromDate(finEssai),
        'date_expiration_abonnement': Timestamp.fromDate(finEssai),
        'date_limite_activation': Timestamp.fromDate(limiteActivation),
        'mode_saisie': 'detail',
        'delai_modification_heures': 30,
        'agents_voient_autres_stands': false,
        'visibilite_stands': 'ferme',
        'seuil_alerte_especes': 50000,
        'seuil_critique_especes': 20000,
        'seuil_alerte_sim': 30000,
        'seuil_critique_sim': 10000,
      });

      // Créer le profil utilisateur
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': 'gestionnaire',
        'entreprise_id': entrepriseId,
        'stand_id': null,
        'mot_de_passe_provisoire': false,
        'actif': true,
        'email_verifie': false,
        'permissions': [],
        'date_creation': Timestamp.fromDate(now),
        'date_limite_activation': Timestamp.fromDate(limiteActivation),
      });

      // Ne pas déconnecter : l'utilisateur accède directement au dashboard
      // avec une bannière l'invitant à vérifier son email

      // Charger son profil pour l'authentifier dans l'app
      await _chargerProfilFirebase(uid);

      return {'success': true, 'entreprise_id': entrepriseId, 'user_id': uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreur(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur inattendue: $e'};
    }
  }

  // ── Chargement des données ─────────────────────────────────────────────────
  Future<void> _chargerEntreprise(String entrepriseId) async {
    try {
      final doc = await _db.collection('entreprises').doc(entrepriseId).get();
      if (doc.exists) {
        _entrepriseActive = EntrepriseModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Erreur chargement entreprise: $e');
    }
  }

  Future<void> _chargerMembres() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    try {
      final snap = await _db.collection('users')
          .where('entreprise_id', isEqualTo: _utilisateurConnecte!.entrepriseId)
          .get();
      _membres = snap.docs
          .map((d) => UserModel.fromFirestore(d.data(), d.id))
          .where((u) => u.id != _utilisateurConnecte!.id)
          .toList();
    } catch (e) {
      debugPrint('Erreur chargement membres: $e');
    }
  }

  Future<void> _chargerStands() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    try {
      final snap = await _db.collection('stands')
          .where('entreprise_id', isEqualTo: _utilisateurConnecte!.entrepriseId)
          .get();
      _stands = snap.docs
          .map((d) => StandModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur chargement stands: $e');
    }
  }

  Future<void> _chargerTauxRistourne() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    try {
      final snap = await _db.collection('taux_ristourne')
          .where('entreprise_id', isEqualTo: _utilisateurConnecte!.entrepriseId)
          .get();
      _tauxRistourne = snap.docs
          .map((d) => TauxRistourne.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur chargement taux ristourne: $e');
    }
  }

  Future<void> _chargerAlertes() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    try {
      final snap = await _db.collection('alertes')
          .where('entreprise_id', isEqualTo: _utilisateurConnecte!.entrepriseId)
          .get();
      _alertes = snap.docs
          .map((d) => AlerteModel.fromFirestore(d.data(), d.id))
          .toList();
      _alertes.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    } catch (e) {
      debugPrint('Erreur chargement alertes: $e');
    }
  }

  Future<void> _chargerDemandesReequilibrage() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    try {
      final snap = await _db.collection('demandes_reequilibrage')
          .where('entreprise_id', isEqualTo: _utilisateurConnecte!.entrepriseId)
          .get();
      _demandesReequil = snap.docs
          .map((d) => DemandeReequilibrage.fromFirestore(d.data(), d.id))
          .toList();
      _demandesReequil.sort((a, b) => b.dateDemande.compareTo(a.dateDemande));
    } catch (e) {
      debugPrint('Erreur chargement demandes: $e');
    }
  }

  Future<void> chargerOperationsStand(String standId, {int limite = 50}) async {
    try {
      final snap = await _db.collection('operations')
          .where('stand_id', isEqualTo: standId)
          .get();
      _operations = snap.docs
          .map((d) => OperationModel.fromFirestore(d.data(), d.id))
          .toList();
      _operations.sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
      if (_operations.length > limite) {
        _operations = _operations.sublist(0, limite);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement opérations: $e');
    }
  }

  // ── Rafraîchir toutes les données ─────────────────────────────────────────
  Future<void> rafraichir() async {
    if (_utilisateurConnecte?.entrepriseId == null) return;
    _setChargement(true);
    await Future.wait([
      _chargerEntreprise(_utilisateurConnecte!.entrepriseId!),
      _chargerMembres(),
      _chargerStands(),
      _chargerTauxRistourne(),
      _chargerAlertes(),
      _chargerDemandesReequilibrage(),
    ]);
    _setChargement(false);
    notifyListeners();
  }

  // ── Gestion des stands ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> creerStand({
    required String nom,
    required String lieu,
    required List<SimCard> sims,
    double capitalEspecesInitial = 0,
    String? latitude,
    String? longitude,
  }) async {
    try {
      final ref = _db.collection('stands').doc();
      final stand = StandModel(
        id: ref.id,
        nom: nom,
        lieu: lieu,
        entrepriseId: _utilisateurConnecte!.entrepriseId!,
        sims: sims,
        soldeEspeces: capitalEspecesInitial,
        dateCreation: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      );
      await ref.set(stand.toFirestore());

      // Enregistrer le mouvement capital initial si non nul
      if (capitalEspecesInitial > 0) {
        await _db.collection('mouvements_capital').doc().set({
          'stand_id': ref.id,
          'entreprise_id': _utilisateurConnecte!.entrepriseId!,
          'type': 'capital_initial_especes',
          'montant': capitalEspecesInitial,
          'motif': 'Capital initial espèces à la création du stand',
          'date': Timestamp.fromDate(DateTime.now()),
          'effectue_par': _utilisateurConnecte!.id,
        });
      }
      for (final sim in sims) {
        if (sim.solde > 0) {
          await _db.collection('mouvements_capital').doc().set({
            'stand_id': ref.id,
            'entreprise_id': _utilisateurConnecte!.entrepriseId!,
            'type': 'capital_initial_sim',
            'operateur': sim.operateur,
            'montant': sim.solde,
            'motif': 'Capital initial SIM ${sim.operateur} à la création du stand',
            'date': Timestamp.fromDate(DateTime.now()),
            'effectue_par': _utilisateurConnecte!.id,
          });
        }
      }

      _stands.add(stand);
      notifyListeners();
      return {'success': true, 'stand_id': ref.id};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> affecterAgent({
    required String standId,
    required String agentId,
  }) async {
    try {
      final agent = _membres.firstWhere((m) => m.id == agentId);
      final maintenant = DateTime.now();

      // Mettre à jour l'ancien stand de l'agent si besoin
      final standIndex = _stands.indexWhere((s) => s.id == standId);
      if (standIndex == -1) return {'success': false, 'erreur': 'Stand introuvable'};

      final stand = _stands[standIndex];

      // Clôturer l'affectation précédente dans l'historique
      final historique = List<AffectationAgent>.from(stand.historiqueAgents);
      if (stand.agentActuelId != null) {
        final idx = historique.indexWhere(
          (h) => h.agentId == stand.agentActuelId && h.dateFin == null,
        );
        if (idx != -1) {
          historique[idx] = AffectationAgent(
            agentId: historique[idx].agentId,
            agentNom: historique[idx].agentNom,
            dateDebut: historique[idx].dateDebut,
            dateFin: maintenant,
          );
        }
      }

      // Ajouter nouvelle affectation
      historique.add(AffectationAgent(
        agentId: agentId,
        agentNom: agent.nomComplet,
        dateDebut: maintenant,
      ));

      // Mettre à jour Firestore — stand
      await _db.collection('stands').doc(standId).update({
        'agent_actuel_id': agentId,
        'agent_actuel_nom': agent.nomComplet,
        'date_affectation_agent': Timestamp.fromDate(maintenant),
        'historique_agents': historique.map((h) => h.toMap()).toList(),
      });

      // Mettre à jour Firestore — agent
      await _db.collection('users').doc(agentId).update({
        'stand_id': standId,
        'date_affectation_stand': Timestamp.fromDate(maintenant),
      });

      await rafraichir();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Gestion capital stand ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> ajusterCapitalStand({
    required String standId,
    required String type, // ajout_especes | retrait_especes | ajout_sim | retrait_sim
    required double montant,
    required String motif,
    String? operateur,
  }) async {
    try {
      final standIndex = _stands.indexWhere((s) => s.id == standId);
      if (standIndex == -1) return {'success': false, 'erreur': 'Stand introuvable'};

      final stand = _stands[standIndex];
      final Map<String, dynamic> updates = {};

      if (type == 'ajout_especes') {
        updates['solde_especes'] = stand.soldeEspeces + montant;
      } else if (type == 'retrait_especes') {
        if (stand.soldeEspeces < montant) {
          return {'success': false, 'erreur': 'Solde espèces insuffisant'};
        }
        updates['solde_especes'] = stand.soldeEspeces - montant;
      } else if (type == 'ajout_sim' && operateur != null) {
        final sims = stand.sims.map((s) {
          if (s.operateur == operateur) return s.copyWith(solde: s.solde + montant);
          return s;
        }).toList();
        updates['sims'] = sims.map((s) => s.toMap()).toList();
      } else if (type == 'retrait_sim' && operateur != null) {
        final sim = stand.sims.firstWhere((s) => s.operateur == operateur);
        if (sim.solde < montant) {
          return {'success': false, 'erreur': 'Solde SIM $operateur insuffisant'};
        }
        final sims = stand.sims.map((s) {
          if (s.operateur == operateur) return s.copyWith(solde: s.solde - montant);
          return s;
        }).toList();
        updates['sims'] = sims.map((s) => s.toMap()).toList();
      }

      await _db.collection('stands').doc(standId).update(updates);

      // Enregistrer le mouvement
      await _db.collection('mouvements_capital').doc().set({
        'stand_id': standId,
        'entreprise_id': _utilisateurConnecte!.entrepriseId,
        'effectue_par': _utilisateurConnecte!.id,
        'type': type,
        'operateur': operateur,
        'montant': montant,
        'motif': motif,
        'date': Timestamp.now(),
      });

      await rafraichir();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Saisie d'opération ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saisirOperation({
    required String standId,
    required String operateur,
    required String typeOperation,
    required double montant,
    String? numeroClient,
    String? nomClient,
  }) async {
    try {
      final user = _utilisateurConnecte!;
      final standIndex = _stands.indexWhere((s) => s.id == standId);
      if (standIndex == -1) return {'success': false, 'erreur': 'Stand introuvable'};

      final stand = _stands[standIndex];
      final maintenant = DateTime.now();

      // Calculer la ristourne
      final ristourne = _calculerRistourne(operateur, typeOperation, montant, maintenant);

      // Vérifier les soldes avant d'enregistrer
      final typeOp = TypeOperation.fromCode(typeOperation);
      if (typeOp == TypeOperation.retrait) {
        if (stand.soldeEspeces < montant) {
          return {'success': false, 'erreur': 'Espèces insuffisantes pour ce retrait (${stand.soldeEspeces.toStringAsFixed(0)} FCFA disponibles)'};
        }
      } else {
        final soldeSim = stand.soldeSim(operateur);
        if (soldeSim < montant) {
          return {'success': false, 'erreur': 'Solde SIM $operateur insuffisant (${soldeSim.toStringAsFixed(0)} FCFA disponibles)'};
        }
      }

      // Délai de modification
      final delaiHeures = _entrepriseActive?.delaiModificationHeures ?? 30;
      // Créer l'opération
      final ref = _db.collection('operations').doc();
      final operation = OperationModel(
        id: ref.id,
        standId: standId,
        standNom: stand.nom,
        agentId: user.id,
        agentNom: user.nomComplet,
        entrepriseId: user.entrepriseId!,
        operateur: operateur,
        typeOperation: typeOperation,
        montant: montant,
        ristourneCalculee: ristourne,
        numeroClient: numeroClient,
        nomClient: nomClient,
        dateHeure: maintenant,
        modifiable: true,
      );

      await ref.set(operation.toFirestore());

      // Mettre à jour les soldes du stand
      final Map<String, dynamic> updates = {};
      final impactEsp = operation.impactEspeces;
      final impactSim = operation.impactSim;

      updates['solde_especes'] = stand.soldeEspeces + impactEsp;

      final simsUpdated = stand.sims.map((s) {
        if (s.operateur == operateur) {
          return s.copyWith(solde: s.solde + impactSim);
        }
        return s;
      }).toList();
      updates['sims'] = simsUpdated.map((s) => s.toMap()).toList();

      await _db.collection('stands').doc(standId).update(updates);

      // Vérifier les alertes après mise à jour
      final newSoldeEspeces = stand.soldeEspeces + impactEsp;
      final newSoldeSim = stand.soldeSim(operateur) + impactSim;
      await _verifierEtCreerAlertes(stand, newSoldeEspeces, operateur, newSoldeSim);

      // Planifier désactivation de la modifiabilité
      Future.delayed(Duration(hours: delaiHeures), () async {
        await _db.collection('operations').doc(ref.id).update({'modifiable': false});
      });

      await rafraichir();
      return {'success': true, 'ristourne': ristourne};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  double _calculerRistourne(String operateur, String typeOperation, double montant, DateTime date) {
    try {
      final taux = _tauxRistourne.firstWhere(
        (t) => t.operateur == operateur &&
               t.typeOperation == typeOperation &&
               t.isActifPour(date),
      );
      return taux.calculerRistourne(montant);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _verifierEtCreerAlertes(
    StandModel stand,
    double newSoldeEspeces,
    String operateur,
    double newSoldeSim,
  ) async {
    if (_entrepriseActive == null) return;
    final ent = _entrepriseActive!;

    // Alerte espèces
    String? typeAlerteEsp;
    if (newSoldeEspeces <= ent.seuilCritiqueEspeces) {
      typeAlerteEsp = 'especes_critique';
    } else if (newSoldeEspeces <= ent.seuilAlerteEspeces) {
      typeAlerteEsp = 'especes_basse';
    }

    if (typeAlerteEsp != null) {
      await _db.collection('alertes').doc().set({
        'stand_id': stand.id,
        'stand_nom': stand.nom,
        'entreprise_id': ent.id,
        'type': typeAlerteEsp,
        'operateur': null,
        'montant_actuel': newSoldeEspeces,
        'seuil': typeAlerteEsp == 'especes_critique'
            ? ent.seuilCritiqueEspeces
            : ent.seuilAlerteEspeces,
        'lue': false,
        'date_creation': Timestamp.now(),
      });
    }

    // Alerte SIM
    String? typeAlerteSim;
    if (newSoldeSim <= ent.seuilCritiqueSim) {
      typeAlerteSim = 'sim_critique';
    } else if (newSoldeSim <= ent.seuilAlerteSim) {
      typeAlerteSim = 'sim_basse';
    }

    if (typeAlerteSim != null) {
      await _db.collection('alertes').doc().set({
        'stand_id': stand.id,
        'stand_nom': stand.nom,
        'entreprise_id': ent.id,
        'type': typeAlerteSim,
        'operateur': operateur,
        'montant_actuel': newSoldeSim,
        'seuil': typeAlerteSim == 'sim_critique'
            ? ent.seuilCritiqueSim
            : ent.seuilAlerteSim,
        'lue': false,
        'date_creation': Timestamp.now(),
      });
    }
  }

  // ── Demande de rééquilibrage (par agent) ──────────────────────────────────
  Future<Map<String, dynamic>> creerDemandeReequilibrage({
    required String standId,
    required String type,
    required double montant,
    required String motif,
    String? operateurSource,
    String? operateurDestination,
  }) async {
    try {
      final user = _utilisateurConnecte!;
      final stand = _stands.firstWhere((s) => s.id == standId);

      final ref = _db.collection('demandes_reequilibrage').doc();
      await ref.set({
        'stand_id': standId,
        'stand_nom': stand.nom,
        'agent_id': user.id,
        'agent_nom': user.nomComplet,
        'entreprise_id': user.entrepriseId,
        'type': type,
        'operateur_source': operateurSource,
        'operateur_destination': operateurDestination,
        'montant': montant,
        'motif': motif,
        'statut': 'en_attente',
        'date_demande': Timestamp.now(),
        'date_traitement': null,
        'traite_par': null,
        'motif_refus': null,
      });

      await _chargerDemandesReequilibrage();
      notifyListeners();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Approuver/Refuser rééquilibrage ───────────────────────────────────────
  Future<Map<String, dynamic>> traiterDemandeReequilibrage({
    required String demandeId,
    required bool approuve,
    String? motifRefus,
  }) async {
    try {
      final demande = _demandesReequil.firstWhere((d) => d.id == demandeId);
      final user = _utilisateurConnecte!;

      await _db.collection('demandes_reequilibrage').doc(demandeId).update({
        'statut': approuve ? 'approuve' : 'refuse',
        'date_traitement': Timestamp.now(),
        'traite_par': user.id,
        'motif_refus': motifRefus,
      });

      // Si approuvé : appliquer le rééquilibrage sur le stand
      if (approuve) {
        switch (demande.type) {
          case 'especes_vers_sim':
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'retrait_especes',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
            );
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'ajout_sim',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
              operateur: demande.operateurDestination,
            );
            break;
          case 'sim_vers_especes':
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'retrait_sim',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
              operateur: demande.operateurSource,
            );
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'ajout_especes',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
            );
            break;
          case 'sim_vers_sim':
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'retrait_sim',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
              operateur: demande.operateurSource,
            );
            await ajusterCapitalStand(
              standId: demande.standId,
              type: 'ajout_sim',
              montant: demande.montant,
              motif: 'Rééquilibrage approuvé: ${demande.motif}',
              operateur: demande.operateurDestination,
            );
            break;
        }
        // rééquilibrage effectué
      }

      await _chargerDemandesReequilibrage();
      notifyListeners();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Taux de ristourne ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> configurerTauxRistourne({
    required String operateur,
    required String typeOperation,
    required double taux,
    required DateTime dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final ref = _db.collection('taux_ristourne').doc();
      await ref.set({
        'entreprise_id': _utilisateurConnecte!.entrepriseId,
        'operateur': operateur,
        'type_operation': typeOperation,
        'taux': taux,
        'date_debut': Timestamp.fromDate(dateDebut),
        'date_fin': dateFin != null ? Timestamp.fromDate(dateFin) : null,
      });
      await _chargerTauxRistourne();
      notifyListeners();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Ajouter membre (agent/contrôleur) ─────────────────────────────────────
  Future<Map<String, dynamic>> ajouterMembre({
    required String email,
    required String prenom,
    required String nom,
    required String telephone,
    required String role,
    List<String> permissions = const [],
  }) async {
    try {
      final entrepriseId = _utilisateurConnecte!.entrepriseId!;
      final motDePasseProv = _genererMotDePasse();

      // Vérifier email existant
      final existing = await _db.collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'erreur': 'Cet email est déjà utilisé.'};
      }

      // Créer compte via REST API
      final uid = await _creerCompteViaRestApi(email, motDePasseProv);
      if (uid == null) return {'success': false, 'erreur': 'Impossible de créer le compte.'};

      await _db.collection('users').doc(uid).set({
        'id': uid,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': role,
        'entreprise_id': entrepriseId,
        'stand_id': null,
        'mot_de_passe_provisoire': true,
        'code_provisoire': motDePasseProv,
        'actif': true,
        'permissions': permissions,
        'date_creation': Timestamp.now(),
      });

      await _chargerMembres();
      notifyListeners();

      return {
        'success': true,
        'user_id': uid,
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'role': role,
        'mot_de_passe_provisoire': motDePasseProv,
      };
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  Future<String?> _creerCompteViaRestApi(String email, String password) async {
    try {
      // Utiliser la même API key que firebase_options.dart
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY',
          defaultValue: 'AIzaSyD-YY2qUVN7GadnJjMfqovBL7tkJjEJBZQ');
      final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body)['localId'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _genererMotDePasse() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = List.generate(8, (i) => chars[DateTime.now().microsecond % chars.length + i < chars.length ? DateTime.now().microsecond % chars.length + i : i]);
    return random.join();
  }

  // ── Marquer alerte comme lue ───────────────────────────────────────────────
  Future<void> marquerAlerteLue(String alerteId) async {
    await _db.collection('alertes').doc(alerteId).update({'lue': true});
    final idx = _alertes.indexWhere((a) => a.id == alerteId);
    if (idx != -1) {
      _alertes[idx] = AlerteModel(
        id: _alertes[idx].id,
        standId: _alertes[idx].standId,
        standNom: _alertes[idx].standNom,
        entrepriseId: _alertes[idx].entrepriseId,
        type: _alertes[idx].type,
        operateur: _alertes[idx].operateur,
        montantActuel: _alertes[idx].montantActuel,
        seuil: _alertes[idx].seuil,
        lue: true,
        dateCreation: _alertes[idx].dateCreation,
      );
      notifyListeners();
    }
  }

  // ── Mettre à jour config entreprise ──────────────────────────────────────
  Future<Map<String, dynamic>> mettreAJourConfigEntreprise(
      Map<String, dynamic> config) async {
    try {
      await _db.collection('entreprises')
          .doc(_utilisateurConnecte!.entrepriseId)
          .update(config);
      await _chargerEntreprise(_utilisateurConnecte!.entrepriseId!);
      notifyListeners();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Changer mot de passe ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> changerMotDePasse({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!, password: ancienMotDePasse,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(nouveauMotDePasse);
      await _db.collection('users').doc(user.uid).update({
        'mot_de_passe_provisoire': false,
      });
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'erreur': _traduireErreur(e.code)};
    } catch (e) {
      return {'success': false, 'erreur': 'Erreur: $e'};
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setChargement(bool val) {
    _chargement = val;
    notifyListeners();
  }

  String _traduireErreur(String code) {
    switch (code) {
      case 'user-not-found':     return 'Aucun compte avec cet identifiant.';
      case 'wrong-password':     return 'Mot de passe incorrect.';
      case 'invalid-credential': return 'Email ou mot de passe incorrect.';
      case 'too-many-requests':  return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed': return 'Pas de connexion internet.';
      case 'email-already-in-use':   return 'Cet email est déjà utilisé.';
      case 'weak-password':      return 'Mot de passe trop faible (6 caractères minimum).';
      default:                   return 'Erreur ($code).';
    }
  }
}
