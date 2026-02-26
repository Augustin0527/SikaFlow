import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../gestionnaire/gestionnaire_dashboard.dart';
import '../agent/agent_dashboard.dart';
import '../controleur/controleur_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../auth/changer_mdp_screen.dart';
import 'inscription_screen.dart';
import 'mot_de_passe_oublie_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? emailPrerempli;

  const LoginScreen({super.key, this.emailPrerempli});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  bool _chargementLocal = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // Pré-remplir l'email si venant de l'inscription
    _emailCtrl = TextEditingController(text: widget.emailPrerempli ?? '');

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animCtrl,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animCtrl,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargementLocal = true);

    final provider = context.read<AppProvider>();
    final ok = await provider.seConnecter(
        _emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    setState(() => _chargementLocal = false);

    if (ok) {
      // ✅ Connexion réussie — naviguer directement vers le bon dashboard
      final user = provider.utilisateurConnecte;
      if (user == null) {
        _showErreur('Profil introuvable. Contactez l\'administrateur.');
        return;
      }

      Widget destination;
      if (user.motDePasseProvisoire) {
        destination = const ChangerMotDePasseScreen(obligatoire: true);
      } else {
        switch (user.role) {
          case 'super_admin':
            destination = const AdminDashboard();
            break;
          case 'gestionnaire':
            destination = const GestionnaireDashboard();
            break;
          case 'agent':
            destination = const AgentDashboard();
            break;
          case 'controleur':
            destination = const ControleurDashboard();
            break;
          default:
            _showErreur('Rôle non reconnu : ${user.role}');
            return;
        }
      }

      // Remplacer toute la pile de navigation par le dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      _showErreur(provider.erreur ?? 'Email ou mot de passe incorrect');
    }
  }

  void _showErreur(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 44),
                  // Message de bienvenue si venant de l'inscription
                  if (widget.emailPrerempli != null) ...[
                    _buildBandeauBienvenue(),
                    const SizedBox(height: 16),
                  ],
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildFormCard(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildFooter(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBandeauBienvenue() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Compte créé avec succès ! Entrez votre mot de passe pour accéder à votre tableau de bord.',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 13,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              size: 46, color: Colors.white),
        ),
        const SizedBox(height: 18),
        const Text('SikaFlow',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        const Text('Système de gestion des opérations Mobile Money',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connexion',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Entrez votre email et mot de passe',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),

            // Email
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
                final reg = RegExp(
                    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                if (!reg.hasMatch(v.trim())) {
                  return 'Format email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Mot de passe
            TextFormField(
              controller: _passCtrl,
              obscureText: !_passVisible,
              style: const TextStyle(color: Colors.white),
              onFieldSubmitted: (_) => _seConnecter(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _passVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textSecondary),
                  onPressed: () =>
                      setState(() => _passVisible = !_passVisible),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Mot de passe requis' : null,
            ),
            const SizedBox(height: 8),

            // Lien mot de passe oublié
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MotDePasseOublieScreen(
                      emailInitial: _emailCtrl.text.trim().isNotEmpty
                          ? _emailCtrl.text.trim()
                          : null,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton SE CONNECTER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _chargementLocal ? null : _seConnecter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _chargementLocal
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('SE CONNECTER',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text('Pas encore de compte ?',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const InscriptionScreen()),
            ),
            icon: const Icon(Icons.add_business_rounded,
                color: AppTheme.accentOrange),
            label: const Text('Créer mon entreprise',
                style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side:
                  const BorderSide(color: AppTheme.accentOrange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
