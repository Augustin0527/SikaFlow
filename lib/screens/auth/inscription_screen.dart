import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen>
    with SingleTickerProviderStateMixin {

  final _pageCtrl = PageController();
  int _etape = 0;   // 0 = formulaire, 1 = succès
  bool _chargement = false;

  // ── Contrôleurs ──────────────────────────────────────────────────────────
  final _formKey         = GlobalKey<FormState>();
  final _prenomCtrl      = TextEditingController();
  final _nomCtrl         = TextEditingController();
  final _telCtrl         = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _nomEntCtrl      = TextEditingController();
  final _descCtrl        = TextEditingController();

  bool _passVisible        = false;
  bool _passConfirmVisible = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _prenomCtrl.dispose(); _nomCtrl.dispose(); _telCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _passConfirmCtrl.dispose();
    _nomEntCtrl.dispose(); _descCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Inscription ──────────────────────────────────────────────────────────
  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    final provider = context.read<AppProvider>();
    final result = await provider.inscrireGestionnaire(
      email:         _emailCtrl.text.trim(),
      motDePasse:    _passCtrl.text,
      prenom:        _prenomCtrl.text.trim(),
      nom:           _nomCtrl.text.trim(),
      telephone:     _telCtrl.text.trim(),
      nomEntreprise: _nomEntCtrl.text.trim(),
      description:   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (result['success'] == true) {
      if (!mounted) return;
      setState(() => _etape = 1);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      final errMsg = result['erreur'] ?? result['message'] ?? 'Erreur lors de la création';
      _showSnack(errMsg, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFormulaire(),
              _buildSucces(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ÉTAPE 1 — Formulaire complet
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFormulaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── En-tête ──
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Créer mon espace',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Text('Inscription Gestionnaire',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 28),

            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section profil ──────────────────────────────────
                    _sectionLabel('Votre profil', Icons.person_rounded),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _champ(_prenomCtrl, 'Prénom', requis: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _champ(_nomCtrl, 'Nom', requis: true)),
                    ]),
                    const SizedBox(height: 10),
                    _champTelephone(),
                    const SizedBox(height: 24),

                    // ── Section connexion ────────────────────────────────
                    _sectionLabel('Identifiants de connexion', Icons.lock_outline_rounded),
                    const SizedBox(height: 12),
                    _champEmail(),
                    const SizedBox(height: 10),
                    _champMotDePasse(),
                    const SizedBox(height: 10),
                    _champConfirmMdp(),
                    const SizedBox(height: 24),

                    // ── Section entreprise ───────────────────────────────
                    _sectionLabel('Votre entreprise', Icons.business_rounded),
                    const SizedBox(height: 12),
                    _champ(_nomEntCtrl, 'Nom de l\'entreprise',
                        icone: Icons.store_rounded, requis: true),
                    const SizedBox(height: 10),
                    _champDescription(),

                    // ── Info activation ──────────────────────────────────
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.accentOrange, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Un email de confirmation vous sera envoyé.\nVotre compte sera activé après vérification.\nSans activation sous 72h, le compte sera supprimé.',
                              style: TextStyle(
                                  color: AppTheme.accentOrange,
                                  fontSize: 12, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Bouton créer ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _chargement ? null : _inscrire,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _chargement
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.rocket_launch_rounded,
                                color: Colors.white),
                        label: Text(
                          _chargement ? 'Création en cours...' : 'CRÉER MON ESPACE',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Lien connexion ───────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(Routes.connexion),
                        child: const Text(
                          'Déjà un compte ? Se connecter',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ══════════════════════════════════════════════════════════════════════════
  // ÉTAPE 2 — Succès
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSucces() {
    final provider = context.read<AppProvider>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Icône succès
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.success, width: 2.5),
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 62),
            ),
            const SizedBox(height: 28),
            const Text(
              'Compte créé !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bienvenue sur SikaFlow !\n\nUn email de vérification a été envoyé à\n${_emailCtrl.text.trim()}\n\nVérifiez votre boîte mail pour activer votre compte.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sans activation de votre email sous 72h, le compte sera automatiquement supprimé.',
                      style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Bouton accéder
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (provider.estConnecte) {
                    context.go(Routes.gestionnaire);
                  } else {
                    context.go('${Routes.connexion}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
                label: const Text(
                  'ACCÉDER À MON ESPACE',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(Routes.connexion),
              child: const Text(
                'Se connecter plus tard',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Widgets utilitaires ──────────────────────────────────────────────────

  Widget _sectionLabel(String label, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppTheme.accentOrange, size: 16),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: AppTheme.accentOrange,
              fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }

  Widget _champ(TextEditingController ctrl, String label,
      {IconData? icone, bool requis = false, TextInputType? type}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icone != null ? Icon(icone) : null,
      ),
      validator: requis
          ? (v) => (v == null || v.trim().isEmpty) ? '$label requis' : null
          : null,
    );
  }

  Widget _champTelephone() {
    return TextFormField(
      controller: _telCtrl,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Téléphone',
        prefixIcon: Icon(Icons.phone_rounded),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Téléphone requis';
        if (v.trim().length < 8) return 'Numéro invalide';
        return null;
      },
    );
  }

  Widget _champEmail() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Adresse email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email requis';
        if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
        return null;
      },
    );
  }

  Widget _champMotDePasse() {
    return TextFormField(
      controller: _passCtrl,
      obscureText: !_passVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(_passVisible
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: () => setState(() => _passVisible = !_passVisible),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Mot de passe requis';
        if (v.length < 6) return 'Minimum 6 caractères';
        return null;
      },
    );
  }

  Widget _champConfirmMdp() {
    return TextFormField(
      controller: _passConfirmCtrl,
      obscureText: !_passConfirmVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Confirmer le mot de passe',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(_passConfirmVisible
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: () => setState(
              () => _passConfirmVisible = !_passConfirmVisible),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirmation requise';
        if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
        return null;
      },
    );
  }

  Widget _champDescription() {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 2,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Description (optionnel)',
        prefixIcon: Icon(Icons.description_outlined),
        alignLabelWithHint: true,
      ),
    );
  }
}
