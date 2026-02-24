import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Gestion des Membres'),
        backgroundColor: AppTheme.primaryDark,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentOrange,
          labelColor: AppTheme.accentOrange,
          unselectedLabelColor: AppTheme.textHint,
          tabs: const [
            Tab(text: 'Agents'),
            Tab(text: 'Contrôleurs'),
            Tab(text: 'Assignations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AgentsTab(onAjouter: () => _dialogAjouterMembre(context, 'agent')),
          _ControleursTab(onAjouter: () => _dialogAjouterMembre(context, 'controleur')),
          const _AssignationsTab(),
        ],
      ),
    );
  }

  // ─── Dialog ajout membre ───────────────────────────────────────────────────
  void _dialogAjouterMembre(BuildContext context, String role) {
    final nomCtrl    = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl    = TextEditingController();
    final emailCtrl  = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool chargement  = false;
    Map<String, String>? resultat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20),
          child: resultat != null
              ? _buildSuccessSheet(ctx, resultat!, role)
              : Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Titre ──
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (role == 'agent'
                                        ? AppTheme.success
                                        : AppTheme.moovBlue)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                role == 'agent'
                                    ? Icons.person_rounded
                                    : Icons.verified_user_rounded,
                                color: role == 'agent'
                                    ? AppTheme.success
                                    : AppTheme.moovBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ajouter un ${role == 'agent' ? 'Agent' : 'Contrôleur'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Prénom / Nom ──
                        Row(
                          children: [
                            Expanded(child: _champ(prenomCtrl, 'Prénom', Icons.person_outline_rounded)),
                            const SizedBox(width: 10),
                            Expanded(child: _champ(nomCtrl, 'Nom', Icons.badge_outlined)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Téléphone (format Bénin) ──
                        TextFormField(
                          controller: telCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: const Icon(Icons.phone_android_rounded),
                            prefix: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('+229 01',
                                  style: TextStyle(
                                      color: AppTheme.accentOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            hintText: '12 34 56 78',
                            hintStyle: const TextStyle(color: AppTheme.textHint),
                          ),
                          maxLength: 8,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Téléphone requis';
                            if (v.length != 8) return '8 chiffres après +229 01';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // ── Email ──
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
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

                        // ── Info invitation ──
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.accentOrange.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.email_rounded,
                                  color: AppTheme.accentOrange, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Un email d\'invitation sera envoyé à cette adresse. '
                                  'La personne devra cliquer sur le lien et définir son mot de passe '
                                  'avant sa première connexion.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Bouton AJOUTER ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: chargement
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setS(() => chargement = true);
                                    final provider = context.read<AppProvider>();
                                    Map<String, String>? res;
                                    final tel = '+22901${telCtrl.text.trim()}';
                                    final email = emailCtrl.text.trim();
                                    if (role == 'agent') {
                                      res = await provider.ajouterAgent(
                                        nom: nomCtrl.text.trim(),
                                        prenom: prenomCtrl.text.trim(),
                                        telephone: tel,
                                        email: email,
                                      );
                                    } else {
                                      res = await provider.ajouterControleur(
                                        nom: nomCtrl.text.trim(),
                                        prenom: prenomCtrl.text.trim(),
                                        telephone: tel,
                                        email: email,
                                      );
                                    }
                                    setS(() {
                                      chargement = false;
                                      if (res != null && res['erreur'] == null) {
                                        resultat = res;
                                      }
                                    });
                                    if (res == null && ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Erreur lors de l\'ajout. Vérifiez les informations.'),
                                          backgroundColor: AppTheme.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (res != null &&
                                        res['erreur'] != null &&
                                        ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(res['erreur']!),
                                          backgroundColor: AppTheme.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      setS(() => chargement = false);
                                    }
                                  },
                            icon: chargement
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.person_add_rounded),
                            label: Text(chargement
                                ? 'Envoi de l\'invitation...'
                                : 'AJOUTER & ENVOYER INVITATION'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessSheet(BuildContext ctx, Map<String, String> res, String role) {
    final email       = res['email'] ?? '';
    final prenom      = res['prenom'] ?? '';
    final nom         = res['nom'] ?? '';
    final telephone   = res['telephone'] ?? '';
    final mdpTemp     = res['mdp_temp'] ?? '';
    final emailEnvoye = res['email_envoye'] == 'true';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // ── Icône succès ──
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 38),
        ),
        const SizedBox(height: 16),
        Text(
          '${role == 'agent' ? 'Agent' : 'Contrôleur'} ajouté !',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '$prenom $nom',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // ── Statut email ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: emailEnvoye
                ? AppTheme.success.withValues(alpha: 0.08)
                : AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emailEnvoye
                  ? AppTheme.success.withValues(alpha: 0.25)
                  : AppTheme.warning.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    emailEnvoye ? Icons.mark_email_read_rounded : Icons.email_outlined,
                    color: emailEnvoye ? AppTheme.success : AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emailEnvoye
                        ? 'Email d\'invitation envoyé'
                        : 'Transmettez le code manuellement',
                    style: TextStyle(
                      color: emailEnvoye ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoLigne(Icons.email_outlined, 'Email', email),
              _infoLigne(Icons.phone_android_rounded, 'Téléphone', telephone),
              const SizedBox(height: 10),

              // ── Code provisoire ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Code provisoire', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          mdpTemp,
                          style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.key_rounded, color: AppTheme.accentOrange, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                emailEnvoye
                    ? 'La personne recevra un email avec un lien pour définir son mot de passe. '
                      'Le code ci-dessus peut aussi être communiqué directement.'
                    : 'Communiquez ce code à la personne. Elle l\'utilisera lors de sa première connexion '
                      'pour définir son propre mot de passe.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.done_rounded),
            label: const Text('FERMER'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoLigne(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textHint),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
          Expanded(
            child: Text(valeur,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _champ(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
    );
  }
}

// ─── Onglet Agents ─────────────────────────────────────────────────────────
class _AgentsTab extends StatelessWidget {
  final VoidCallback onAjouter;
  const _AgentsTab({required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final agents = provider.mesAgents;
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onAjouter,
            backgroundColor: AppTheme.success,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Ajouter un agent'),
          ),
          body: agents.isEmpty
              ? _buildVide('Aucun agent', 'Ajoutez vos premiers agents', Icons.group_off_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: agents.length,
                  itemBuilder: (ctx, i) => _buildMembreCard(agents[i], provider, AppTheme.success),
                ),
        );
      },
    );
  }
}

// ─── Onglet Contrôleurs ─────────────────────────────────────────────────────
class _ControleursTab extends StatelessWidget {
  final VoidCallback onAjouter;
  const _ControleursTab({required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final controleurs = provider.mesControleurs;
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onAjouter,
            backgroundColor: AppTheme.moovBlue,
            icon: const Icon(Icons.verified_user_rounded),
            label: const Text('Ajouter un contrôleur'),
          ),
          body: controleurs.isEmpty
              ? _buildVide('Aucun contrôleur', 'Ajoutez vos contrôleurs', Icons.admin_panel_settings_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: controleurs.length,
                  itemBuilder: (ctx, i) => _buildMembreCard(controleurs[i], provider, AppTheme.moovBlue),
                ),
        );
      },
    );
  }
}

// ─── Onglet Assignations ─────────────────────────────────────────────────────
class _AssignationsTab extends StatelessWidget {
  const _AssignationsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final controleurs = provider.mesControleurs;
        final agentsLibres = provider.agentsNonAssignes();

        if (controleurs.isEmpty) {
          return _buildVide('Aucun contrôleur', 'Ajoutez d\'abord des contrôleurs', Icons.admin_panel_settings_outlined);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Agents non assignés
            if (agentsLibres.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 8),
                    Text('${agentsLibres.length} agent(s) non assigné(s)', style: const TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            // Contrôleurs avec leurs agents
            ...controleurs.map((ctrl) => _buildControleurAssign(ctrl, provider, context)),
          ],
        );
      },
    );
  }

  Widget _buildControleurAssign(UserModel controleur, AppProvider provider, BuildContext context) {
    final agentsAssignes = provider.agentsDuControleur(controleur.id);
    final agentsLibres = provider.agentsNonAssignes();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.moovBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // En-tête contrôleur
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.moovBlue.withValues(alpha: 0.2), AppTheme.moovBlue.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.moovBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${controleur.prenom[0]}${controleur.nom[0]}', style: const TextStyle(color: AppTheme.moovBlue, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controleur.nomComplet, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${agentsAssignes.length} agent(s) assigné(s)', style: const TextStyle(color: AppTheme.moovBlue, fontSize: 11)),
                    ],
                  ),
                ),
                // Bouton ajouter agent à ce contrôleur
                if (agentsLibres.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded, color: AppTheme.accentOrange, size: 20),
                    tooltip: 'Assigner un agent',
                    onPressed: () => _dialogAssignerAgent(context, controleur, agentsLibres, provider),
                  ),
              ],
            ),
          ),
          // Agents assignés
          if (agentsAssignes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun agent assigné', style: TextStyle(color: AppTheme.textHint, fontSize: 12, fontStyle: FontStyle.italic)),
            )
          else
            ...agentsAssignes.map((agent) => _agentAssigneTile(agent, controleur, provider, context)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _agentAssigneTile(UserModel agent, UserModel controleur, AppProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${agent.prenom[0]}${agent.nom[0]}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 11))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.nomComplet, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(agent.telephone.isNotEmpty ? agent.telephone : (agent.email ?? ''), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off_rounded, color: AppTheme.error, size: 18),
            tooltip: 'Désassigner',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Désassigner l\'agent', style: TextStyle(color: Colors.white, fontSize: 16)),
                  content: Text('Retirer ${agent.nomComplet} de ${controleur.nomComplet} ?', style: const TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                    ElevatedButton(
                      onPressed: () {
                        provider.desassignerAgentDeControleur(agentId: agent.id, controleurId: controleur.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('Désassigner'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _dialogAssignerAgent(BuildContext context, UserModel controleur, List<UserModel> agentsLibres, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppTheme.accentOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Assigner à ${controleur.nomComplet}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.divider),
          ...agentsLibres.map((agent) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9)),
              child: Center(child: Text('${agent.prenom[0]}${agent.nom[0]}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            title: Text(agent.nomComplet, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(agent.telephone.isNotEmpty ? agent.telephone : (agent.email ?? ''), style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentOrange, size: 14),
            onTap: () {
              provider.assignerAgentAControleur(agentId: agent.id, controleurId: controleur.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${agent.nomComplet} assigné à ${controleur.nomComplet}'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ));
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Widgets communs ───────────────────────────────────────────────────────
Widget _buildMembreCard(UserModel membre, AppProvider provider, Color color) {
  final pointAuj = membre.estAgent ? provider.getPointDuJour(membre.id) : null;
  String? controleurNom;
  if (membre.estAgent && membre.controleurAssigneId != null) {
    controleurNom = provider.getUtilisateurParId(membre.controleurAssigneId!)?.nomComplet;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('${membre.prenom[0]}${membre.nom[0]}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(membre.nomComplet, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  if (membre.motDePasseProvisoire)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Provisoire', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              Text(
                membre.telephone.isNotEmpty ? membre.telephone : (membre.email ?? ''),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              if (controleurNom != null)
                Text('Contrôleur : $controleurNom', style: const TextStyle(color: AppTheme.moovBlue, fontSize: 11)),
              if (pointAuj != null)
                Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 12),
                  const SizedBox(width: 4),
                  Text('Point fait : ${provider.formaterMontant(pointAuj.totalGeneral)}', style: const TextStyle(color: AppTheme.success, fontSize: 11)),
                ])
              else if (membre.estAgent)
                const Row(children: [
                  Icon(Icons.pending_rounded, color: AppTheme.warning, size: 12),
                  SizedBox(width: 4),
                  Text('Point non soumis', style: TextStyle(color: AppTheme.warning, fontSize: 11)),
                ]),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildVide(String titre, String sous, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: AppTheme.textHint.withValues(alpha: 0.4)),
        const SizedBox(height: 14),
        Text(titre, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(sous, style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
      ],
    ),
  );
}
