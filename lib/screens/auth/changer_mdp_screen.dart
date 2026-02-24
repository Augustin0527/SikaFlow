import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class ChangerMotDePasseScreen extends StatefulWidget {
  final bool obligatoire; // true = 1ère connexion, faux = changement volontaire
  const ChangerMotDePasseScreen({super.key, this.obligatoire = false});

  @override
  State<ChangerMotDePasseScreen> createState() => _ChangerMotDePasseScreenState();
}

class _ChangerMotDePasseScreenState extends State<ChangerMotDePasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ancienCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _ancienVisible = false;
  bool _nouveauVisible = false;
  bool _confirmVisible = false;
  bool _chargement = false;
  // Si true, le mdp provisoire n'est pas demandé (utilisateur connecté via lien Firebase)
  bool _sessionRecente = false;

  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changerMdp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    final provider = context.read<AppProvider>();
    // Si session récente, on passe une chaîne vide pour l'ancien mdp
    final ancienMdp = _sessionRecente ? '' : _ancienCtrl.text;

    final erreur = await provider.changerMotDePasse(
      ancienMdp: ancienMdp,
      nouveauMdp: _nouveauCtrl.text,
    );

    setState(() => _chargement = false);
    if (!mounted) return;

    if (erreur != null) {
      // Si erreur de session, proposer de re-tenter avec le mdp provisoire
      if (erreur.contains('Session expirée') && _sessionRecente) {
        setState(() => _sessionRecente = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez entrer votre code provisoire pour continuer.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erreur),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Mot de passe défini avec succès !'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));

    if (widget.obligatoire && mounted) {
      // La navigation sera gérée par AppRouter (notifyListeners déjà appelé)
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppProvider>().utilisateurConnecte;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: widget.obligatoire
          ? null
          : AppBar(title: const Text('Changer le mot de passe'), backgroundColor: AppTheme.primaryDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.obligatoire) ...[
                const SizedBox(height: 20),
                // Bannière de bienvenue
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentOrange.withValues(alpha: 0.2), AppTheme.accentOrange.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppTheme.accentOrange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bienvenue sur SikaFlow !', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              'Bonjour ${user?.prenom ?? ''} ! Définissez votre mot de passe personnel pour accéder à l\'application.',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Infos compte
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _roleCouleur(user?.role ?? '').withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(
                          '${user?.prenom.isNotEmpty == true ? user!.prenom[0] : ''}${user?.nom.isNotEmpty == true ? user!.nom[0] : ''}',
                          style: TextStyle(color: _roleCouleur(user?.role ?? ''), fontWeight: FontWeight.bold, fontSize: 16),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.nomComplet ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(user?.roleLibelle ?? '', style: TextStyle(color: _roleCouleur(user?.role ?? ''), fontSize: 12)),
                          if (user?.email?.isNotEmpty == true)
                            Text(user!.email!, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Option session récente
                GestureDetector(
                  onTap: () => setState(() => _sessionRecente = !_sessionRecente),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _sessionRecente
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _sessionRecente
                            ? AppTheme.success.withValues(alpha: 0.4)
                            : AppTheme.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sessionRecente ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: _sessionRecente ? AppTheme.success : AppTheme.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'J\'ai cliqué sur le lien dans l\'email d\'invitation',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                widget.obligatoire ? 'Définir votre mot de passe' : 'Nouveau mot de passe',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('Votre mot de passe doit contenir au moins 6 caractères.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Mot de passe provisoire — caché si session récente
                    if (!_sessionRecente) ...[
                      _champPass(
                        ctrl: _ancienCtrl,
                        label: widget.obligatoire ? 'Code provisoire reçu par email' : 'Mot de passe actuel',
                        hint: widget.obligatoire ? 'Code envoyé par votre gestionnaire' : null,
                        visible: _ancienVisible,
                        onToggle: () => setState(() => _ancienVisible = !_ancienVisible),
                        icon: Icons.vpn_key_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _champPass(
                      ctrl: _nouveauCtrl,
                      label: 'Nouveau mot de passe',
                      visible: _nouveauVisible,
                      onToggle: () => setState(() => _nouveauVisible = !_nouveauVisible),
                      icon: Icons.lock_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _champPass(
                      ctrl: _confirmCtrl,
                      label: 'Confirmer le nouveau mot de passe',
                      visible: _confirmVisible,
                      onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
                      icon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v != _nouveauCtrl.text) return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _chargement ? null : _changerMdp,
                        icon: _chargement
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_chargement ? 'En cours...' : 'CONFIRMER LE MOT DE PASSE'),
                      ),
                    ),
                    if (!widget.obligatoire) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _champPass({
    required TextEditingController ctrl,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 12),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
          onPressed: onToggle,
        ),
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Champ requis' : null,
    );
  }

  Color _roleCouleur(String role) {
    switch (role) {
      case 'agent': return AppTheme.success;
      case 'controleur': return AppTheme.moovBlue;
      default: return AppTheme.accentOrange;
    }
  }
}
