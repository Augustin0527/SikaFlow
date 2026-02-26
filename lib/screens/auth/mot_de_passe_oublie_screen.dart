import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class MotDePasseOublieScreen extends StatefulWidget {
  final String? emailInitial;
  const MotDePasseOublieScreen({super.key, this.emailInitial});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _chargement = false;
  bool _emailEnvoye = false;

  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;
  late Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.emailInitial ?? '');
    _animCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    final provider = context.read<AppProvider>();
    final result = await provider.reinitialiserMotDePasse(
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (result['success'] == true) {
      setState(() => _emailEnvoye = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['erreur'] ?? 'Erreur lors de l\'envoi'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Bouton retour ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Icône ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accentOrange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mot de passe oublié',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre email pour recevoir\nun lien de réinitialisation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 36),

                // ── Carte principale ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _emailEnvoye
                        ? _buildSuccessCard()
                        : _buildFormCard(),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Formulaire envoi email ──────────────────────────────────────────────────
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
              offset: const Offset(0, 8)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: widget.emailInitial == null,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Adresse email',
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
            ),
            const SizedBox(height: 12),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accentOrange.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.accentOrange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un lien de réinitialisation vous sera envoyé par email. Vérifiez aussi vos spams.',
                      style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _chargement ? null : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _chargement
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                label: Text(
                  _chargement ? 'Envoi en cours...' : 'ENVOYER LE LIEN',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carte succès ────────────────────────────────────────────────────────────
  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Icône succès
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: AppTheme.success, size: 34),
          ),
          const SizedBox(height: 18),
          const Text(
            'Email envoyé !',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Un lien de réinitialisation a été envoyé à\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                _EtapeItem(
                    numero: '1',
                    texte: 'Ouvrez votre boîte email (vérifiez les spams)'),
                SizedBox(height: 8),
                _EtapeItem(
                    numero: '2',
                    texte: 'Cliquez sur le lien de réinitialisation'),
                SizedBox(height: 8),
                _EtapeItem(
                    numero: '3',
                    texte: 'Choisissez un nouveau mot de passe sécurisé'),
                SizedBox(height: 8),
                _EtapeItem(
                    numero: '4',
                    texte: 'Connectez-vous avec votre nouveau mot de passe'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Renvoyer l'email
          TextButton.icon(
            onPressed: _chargement
                ? null
                : () {
                    setState(() => _emailEnvoye = false);
                  },
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary, size: 16),
            label: const Text('Renvoyer l\'email',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 8),

          // Retour connexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.login_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Retour à la connexion',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget étape ─────────────────────────────────────────────────────────────
class _EtapeItem extends StatelessWidget {
  final String numero;
  final String texte;
  const _EtapeItem({required this.numero, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            numero,
            style: const TextStyle(
                color: AppTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}
