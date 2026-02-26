import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen>
    with SingleTickerProviderStateMixin {

  final _pageCtrl = PageController();
  int  _etape     = 0;   // 0 = formulaire, 1 = confirmation envoyée
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
      // Passer à l'écran de confirmation
      setState(() => _etape = 1);
      _pageCtrl.animateToPage(1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _showSnack(result['erreur'] ?? 'Erreur lors de la création', isError: true);
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
              _buildConfirmation(),
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
                        onPressed: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
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
  // ÉTAPE 2 — Confirmation email envoyé
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

          // Icône email
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: AppTheme.success, size: 48),
          ),
          const SizedBox(height: 24),

          const Text('Vérifiez votre email !',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Text(
            'Un lien de confirmation a été envoyé à\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 32),

          // Étapes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(children: [
              _etapeItem('1', 'Ouvrez votre boîte email',
                  'Vérifiez aussi les spams', Icons.inbox_rounded),
              const Divider(color: AppTheme.divider, height: 20),
              _etapeItem('2', 'Cliquez sur le lien de confirmation',
                  'Le lien est valable 72 heures', Icons.touch_app_rounded),
              const Divider(color: AppTheme.divider, height: 20),
              _etapeItem('3', 'Revenez vous connecter',
                  'Votre espace sera activé automatiquement', Icons.login_rounded),
            ]),
          ),
          const SizedBox(height: 20),

          // Avertissement 72h
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined,
                    color: AppTheme.warning, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sans activation sous 72h, votre compte sera automatiquement supprimé.',
                    style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bouton connexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => LoginScreen(
                        emailPrerempli: _emailCtrl.text.trim())),
                (r) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              label: const Text('ALLER À LA CONNEXION',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(height: 30),
        ],
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
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Téléphone',
        prefixIcon: Icon(Icons.phone_android_rounded),
        prefixText: '+229 01 ',
        prefixStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Téléphone requis';
        if (v.trim().length < 8) return 'Numéro invalide (min. 8 chiffres)';
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
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        hintText: 'exemple@email.com',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email requis';
        final reg = RegExp(
            r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
        if (!reg.hasMatch(v.trim())) return 'Format email invalide';
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
          icon: Icon(
              _passVisible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textSecondary),
          onPressed: () => setState(() => _passVisible = !_passVisible),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Mot de passe requis';
        if (v.length < 8) return 'Minimum 8 caractères';
        if (!RegExp(r'[A-Z]').hasMatch(v)) return '1 majuscule requise';
        if (!RegExp(r'[0-9]').hasMatch(v)) return '1 chiffre requis';
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
          icon: Icon(
              _passConfirmVisible ? Icons.visibility_off : Icons.visibility,
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

  Widget _etapeItem(String num, String titre, String sous, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(num,
              style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(sous,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Icon(icon, color: AppTheme.textHint, size: 18),
      ],
    );
  }
}
