import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _pageCtrl = PageController();

  // 0 = profil, 1 = vérification email, 2 = entreprise
  int _etape = 0;
  bool _passVisible = false;
  bool _passConfirmVisible = false;
  bool _chargement = false;

  // Étape 1 — Profil gestionnaire
  final _nomCtrl        = TextEditingController();
  final _prenomCtrl     = TextEditingController();
  final _telCtrl        = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _passConfirmCtrl= TextEditingController();
  final _formKey1       = GlobalKey<FormState>();

  // Étape 2 — Vérification email
  // On crée un compte temporaire Firebase pour envoyer l'email de vérification
  User? _tempUser;
  bool _verificationEnCours = false;
  int  _secondesRestants = 0;

  // Étape 3 — Entreprise
  final _nomEntrepriseCtrl = TextEditingController();
  final _capitalCtrl       = TextEditingController();
  final _descCtrl          = TextEditingController();
  final _formKey2          = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _passConfirmCtrl.dispose();
    _nomEntrepriseCtrl.dispose(); _capitalCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 1 → 2 : Envoyer email de vérification Firebase
  // ══════════════════════════════════════════════════════════

  Future<void> _envoyerVerification() async {
    if (!_formKey1.currentState!.validate()) return;

    setState(() => _verificationEnCours = true);

    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      // Supprimer l'ancien compte temporaire si existant
      if (_tempUser != null) {
        try { await _tempUser!.delete(); } catch (_) {}
        _tempUser = null;
      }

      UserCredential cred;
      try {
        // Créer un compte Firebase temporaire avec cet email
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // L'email est déjà enregistré — informer l'utilisateur
          _showSnack(
            'Cet email est déjà associé à un compte. Connectez-vous.',
            isError: true,
          );
          setState(() => _verificationEnCours = false);
          return;
        }
        rethrow;
      }

      _tempUser = cred.user;

      // Envoyer l'email de vérification Firebase (vrai email à l'adresse)
      await _tempUser!.sendEmailVerification(
        ActionCodeSettings(
          url: 'https://sikaflow-c8869.web.app',
          handleCodeInApp: false,
        ),
      );

      setState(() {
        _secondesRestants = 60;
        _etape = 1;
      });
      _pageCtrl.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _demarrerCompteur();

      _showSnack(
        'Email de vérification envoyé à $email — vérifiez votre boîte mail.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':     msg = 'Adresse email invalide.'; break;
        case 'weak-password':     msg = 'Mot de passe trop faible (min. 6 caractères).'; break;
        case 'network-request-failed': msg = 'Pas de connexion internet.'; break;
        default: msg = 'Erreur : ${e.message ?? e.code}';
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      _showSnack('Erreur inattendue : $e', isError: true);
    } finally {
      setState(() => _verificationEnCours = false);
    }
  }

  Future<void> _renvoyerVerification() async {
    if (_tempUser == null) {
      await _envoyerVerification();
      return;
    }
    setState(() => _verificationEnCours = true);
    try {
      await _tempUser!.sendEmailVerification();
      setState(() => _secondesRestants = 60);
      _demarrerCompteur();
      _showSnack('Email renvoyé à ${_emailCtrl.text.trim()}', isError: false);
    } catch (e) {
      _showSnack('Erreur lors du renvoi : $e', isError: true);
    } finally {
      setState(() => _verificationEnCours = false);
    }
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 2 : Vérifier que l'email a bien été validé
  // ══════════════════════════════════════════════════════════

  Future<void> _verifierEmailValide() async {
    if (_tempUser == null) {
      _showSnack('Erreur : relancez l\'inscription.', isError: true);
      return;
    }

    setState(() => _chargement = true);

    try {
      // Recharger les infos du compte depuis Firebase
      await _tempUser!.reload();
      _tempUser = FirebaseAuth.instance.currentUser;

      if (_tempUser != null && _tempUser!.emailVerified) {
        // ✅ Email vérifié — aller à l'étape entreprise
        setState(() { _etape = 2; _chargement = false; });
        _pageCtrl.animateToPage(
          2,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _showSnack('Email vérifié ✅ Configurez votre entreprise.', isError: false);
      } else {
        _showSnack(
          'Email pas encore vérifié. Cliquez sur le lien dans votre boîte mail puis réessayez.',
          isError: true,
        );
        setState(() => _chargement = false);
      }
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
      setState(() => _chargement = false);
    }
  }

  void _demarrerCompteur() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _secondesRestants <= 0) return false;
      setState(() => _secondesRestants--);
      return _secondesRestants > 0;
    });
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 3 : Création de l'entreprise
  // ══════════════════════════════════════════════════════════

  Future<void> _finaliser() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_tempUser == null) {
      _showSnack('Session expirée. Recommencez l\'inscription.', isError: true);
      return;
    }

    setState(() => _chargement = true);

    final provider    = context.read<AppProvider>();
    final telComplet  = '+22901${_telCtrl.text.trim()}';

    // Le compte Firebase a déjà été créé et vérifié à l'étape 2.
    // On passe l'UID existant pour que inscrireGestionnaire crée seulement
    // les documents Firestore (entreprise + user) sans recréer le compte Auth.
    final uidExistant = _tempUser?.uid;
    _tempUser = null; // libérer la référence locale (ne pas supprimer)

    final resultat = await provider.inscrireGestionnaire(
      nom:                  _nomCtrl.text.trim(),
      prenom:               _prenomCtrl.text.trim(),
      telephone:            telComplet,
      email:                _emailCtrl.text.trim(),
      motDePasse:           _passCtrl.text,
      nomEntreprise:        _nomEntrepriseCtrl.text.trim(),
    );
    final erreur = resultat['success'] == true ? null : (resultat['erreur'] as String?);

    if (!mounted) return;
    setState(() => _chargement = false);

    if (erreur != null) {
      _showSnack(erreur, isError: true);
      return;
    }

    // ✅ Succès — afficher dialog de bienvenue
    // L'utilisateur est déjà connecté et son profil chargé dans AppProvider.
    // AppRouter va le rediriger automatiquement vers le dashboard
    // dès que le dialog est fermé.
    final nomEntreprise = _nomEntrepriseCtrl.text;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Entreprise créée avec succès !',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '« $nomEntreprise » est maintenant opérationnelle.\n\n'
              'Bienvenue sur votre tableau de bord SikaFlow !',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('ACCÉDER AU TABLEAU DE BORD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    // AppRouter gère la redirection automatique via Consumer<AppProvider>
    // On s'assure juste de revenir à la racine
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 5 : 3),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepper(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildEtape1(), _buildEtapeVerif(), _buildEtape3()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SikaFlow',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Créer votre espace',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Connexion',
                style: TextStyle(color: AppTheme.accentOrange, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Stepper ──────────────────────────────────────────────────────────────

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _stepItem(0, 'Profil',    Icons.person_rounded),
          _stepLine(1),
          _stepItem(1, 'Email',     Icons.verified_rounded),
          _stepLine(2),
          _stepItem(2, 'Entreprise',Icons.business_rounded),
        ],
      ),
    );
  }

  Widget _stepLine(int from) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: _etape >= from ? AppTheme.accentOrange : AppTheme.divider,
    ),
  );

  Widget _stepItem(int index, String label, IconData icon) {
    final active = _etape == index;
    final done   = _etape > index;
    final color  = done ? AppTheme.success : active ? AppTheme.accentOrange : AppTheme.textHint;
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: active ? 2 : 1),
          ),
          child: Icon(done ? Icons.check_rounded : icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
            color: color, fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // ── Étape 1 : Profil ─────────────────────────────────────────────────────

  Widget _buildEtape1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitre('Vos informations', 'Vous serez le gestionnaire principal'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _champ(_prenomCtrl, 'Prénom', Icons.person_outline_rounded, requis: true)),
                const SizedBox(width: 12),
                Expanded(child: _champ(_nomCtrl, 'Nom', Icons.badge_outlined, requis: true)),
              ],
            ),
            const SizedBox(height: 12),
            _champTelephone(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'exemple@email.com',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email requis';
                final reg = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                if (!reg.hasMatch(v.trim())) return 'Format email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _champPass(_passCtrl, 'Mot de passe', _passVisible,
                () => setState(() => _passVisible = !_passVisible)),
            const SizedBox(height: 8),
            _champPassConfirm(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verificationEnCours ? null : _envoyerVerification,
                icon: _verificationEnCours
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(_verificationEnCours
                    ? 'Envoi en cours...'
                    : 'VÉRIFIER MON EMAIL'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _champTelephone() {
    return TextFormField(
      controller: _telCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Téléphone',
        prefixIcon: const Icon(Icons.phone_android_rounded),
        prefix: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('+229 01',
              style: TextStyle(color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        hintText: '12 34 56 78',
        hintStyle: const TextStyle(color: AppTheme.textHint),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Téléphone requis';
        if (v.length != 8) return '8 chiffres requis après +229 01';
        return null;
      },
    );
  }

  // ── Étape 2 : Vérification email ─────────────────────────────────────────

  Widget _buildEtapeVerif() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _sectionTitre('Vérifiez votre email', 'Un lien de confirmation a été envoyé'),
          const SizedBox(height: 16),

          // Bandeau email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded,
                    color: AppTheme.accentOrange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email envoyé à :',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(_emailCtrl.text.trim(),
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comment vérifier votre email :',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                _InstructionLigne(
                  numero: '1',
                  texte: 'Ouvrez votre boîte mail (vérifiez aussi les Spams)',
                ),
                _InstructionLigne(
                  numero: '2',
                  texte: 'Cherchez un email de "noreply@sikaflow-c8869.firebaseapp.com"',
                ),
                _InstructionLigne(
                  numero: '3',
                  texte: 'Cliquez sur le lien "Vérifier l\'adresse email"',
                ),
                _InstructionLigne(
                  numero: '4',
                  texte: 'Revenez ici et cliquez sur "J\'ai vérifié mon email"',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _chargement ? null : _verifierEmailValide,
              icon: _chargement
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: const Text("J'AI VÉRIFIÉ MON EMAIL",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Renvoyer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Pas reçu ? ',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              if (_secondesRestants > 0)
                Text('Renvoyer dans ${_secondesRestants}s',
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 13))
              else
                GestureDetector(
                  onTap: _verificationEnCours ? null : _renvoyerVerification,
                  child: const Text('Renvoyer l\'email',
                      style: TextStyle(color: AppTheme.accentOrange,
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Modifier email
          TextButton.icon(
            onPressed: () async {
              // Supprimer le compte temporaire si existant
              if (_tempUser != null) {
                try { await _tempUser!.delete(); } catch (_) {}
                _tempUser = null;
              }
              setState(() => _etape = 0);
              _pageCtrl.animateToPage(0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut);
            },
            icon: const Icon(Icons.edit_rounded,
                color: AppTheme.textSecondary, size: 16),
            label: const Text('Modifier l\'email',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Étape 3 : Entreprise ─────────────────────────────────────────────────

  Widget _buildEtape3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitre('Votre entreprise', 'Configurez votre espace Mobile Money'),
            const SizedBox(height: 20),
            _champ(_nomEntrepriseCtrl, 'Nom de l\'entreprise',
                Icons.business_rounded, requis: true),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capitalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Capital de départ (FCFA)',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                suffixText: 'FCFA',
                suffixStyle: TextStyle(color: AppTheme.textHint),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Entrez le capital';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            _buildResume(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _etape = 1);
                      _pageCtrl.animateToPage(1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut);
                    },
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textSecondary),
                    label: const Text('Retour',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _chargement ? null : _finaliser,
                    icon: _chargement
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.rocket_launch_rounded),
                    label: const Text('CRÉER MON ESPACE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Widgets utilitaires ──────────────────────────────────────────────────

  Widget _buildResume() {
    if (_prenomCtrl.text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Récapitulatif',
              style: TextStyle(color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _resumeLigne(Icons.person_rounded, 'Gestionnaire',
              '${_prenomCtrl.text} ${_nomCtrl.text.toUpperCase()}'),
          _resumeLigne(Icons.email_outlined, 'Email', _emailCtrl.text.trim()),
          _resumeLigne(Icons.phone_android_rounded, 'Téléphone',
              '+229 01 ${_telCtrl.text.trim()}'),
          if (_nomEntrepriseCtrl.text.isNotEmpty)
            _resumeLigne(Icons.business_rounded, 'Entreprise',
                _nomEntrepriseCtrl.text),
          if (_capitalCtrl.text.isNotEmpty)
            _resumeLigne(Icons.account_balance_wallet_rounded,
                'Capital', '${_capitalCtrl.text} FCFA'),
        ],
      ),
    );
  }

  Widget _resumeLigne(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label : ',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Expanded(
              child: Text(valeur,
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _sectionTitre(String titre, String sous) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sous, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _champ(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, bool requis = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: requis
          ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
          : null,
    );
  }

  Widget _champPass(TextEditingController ctrl, String label,
      bool visible, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textSecondary),
          onPressed: toggle,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Mot de passe requis';
        if (v.length < 6) return 'Minimum 6 caractères';
        return null;
      },
    );
  }

  Widget _champPassConfirm() {
    return TextFormField(
      controller: _passConfirmCtrl,
      obscureText: !_passConfirmVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Confirmer le mot de passe',
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(_passConfirmVisible
              ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textSecondary),
          onPressed: () =>
              setState(() => _passConfirmVisible = !_passConfirmVisible),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirmation requise';
        if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
        return null;
      },
    );
  }
}

// ── Widget stateless pour les instructions ────────────────────────────────────

class _InstructionLigne extends StatelessWidget {
  final String numero;
  final String texte;

  const _InstructionLigne({required this.numero, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(numero,
                  style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
