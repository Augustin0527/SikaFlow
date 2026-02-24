import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/point_journalier.dart';
import '../auth/changer_mdp_screen.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildAccueil(),
          _buildPointJournalier(),
          _buildHistorique(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.primaryDark),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Point du jour'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historique'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccueil() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final user = provider.utilisateurConnecte!;
        final pointAuj = provider.getPointDuJour(user.id);
        final gestionnaire = provider.getUtilisateurParId(user.gestionnaireId ?? '');

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppTheme.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('${user.prenom[0]}${user.nom[0]}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${user.prenom} ${user.nom}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Agent', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                            if (gestionnaire != null)
                              Text('Gestionnaire: ${gestionnaire.nomComplet}', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                        onPressed: () => provider.seDeconnecter(),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                        color: AppTheme.cardDarker,
                        onSelected: (v) {
                          if (v == 'mdp') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangerMotDePasseScreen()));
                          } else {
                            provider.seDeconnecter();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'mdp', child: Row(children: [Icon(Icons.lock_reset_rounded, color: AppTheme.accentOrange, size: 18), SizedBox(width: 8), Text('Changer mot de passe', style: TextStyle(color: Colors.white, fontSize: 13))])),
                          const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded, color: AppTheme.error, size: 18), SizedBox(width: 8), Text('Déconnecter', style: TextStyle(color: AppTheme.error, fontSize: 13))])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Statut du point du jour
                  _buildStatutPointDuJour(pointAuj, provider),
                  const SizedBox(height: 16),
                  if (pointAuj != null) ...[
                    _buildDetailPointAujourdhui(pointAuj, provider),
                    const SizedBox(height: 16),
                  ],
                  // Mon historique résumé
                  _buildResumeHistorique(provider),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatutPointDuJour(PointJournalier? point, AppProvider provider) {
    if (point == null) {
      return GestureDetector(
        onTap: () => setState(() => _navIndex = 1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.warning.withValues(alpha: 0.2), AppTheme.warning.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 32),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Point du jour non soumis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Appuyez ici pour soumettre votre point journalier', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.warning, size: 18),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.success.withValues(alpha: 0.2), AppTheme.success.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Point du jour soumis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Total: ${provider.formaterMontant(point.totalGeneral)}', style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(point.valide ? 'Validé par le contrôleur' : 'En attente de validation', style: TextStyle(color: point.valide ? AppTheme.success : AppTheme.warning, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPointAujourdhui(PointJournalier point, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détail — Aujourd\'hui', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ligneDetail('Espèces', point.montantEspeces, Icons.payments_rounded, AppTheme.accentOrange, provider),
          const Divider(color: AppTheme.divider, height: 16),
          _ligneDetail('SIM MTN', point.soldeMTN, Icons.sim_card_rounded, AppTheme.mtnYellow, provider),
          _ligneDetail('SIM Moov', point.soldeMoov, Icons.sim_card_rounded, AppTheme.moovBlue, provider),
          _ligneDetail('SIM Celtiis', point.soldeCeltiis, Icons.sim_card_rounded, AppTheme.celtiisRed, provider),
          const Divider(color: AppTheme.divider, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(provider.formaterMontant(point.totalGeneral), style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneDetail(String label, double montant, IconData icon, Color color, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Text(provider.formaterMontant(montant), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResumeHistorique(AppProvider provider) {
    final points = provider.mesPointsJournaliers.take(3).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Historique récent', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => setState(() => _navIndex = 2),
                child: const Text('Voir tout', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map((p) => _buildPointMini(p, provider)),
        ],
      ),
    );
  }

  Widget _buildPointMini(PointJournalier p, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.cardDarker, borderRadius: BorderRadius.circular(8)),
            child: Text(p.dateFormatee, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(provider.formaterMontant(p.totalGeneral), style: const TextStyle(color: Colors.white, fontSize: 13))),
          Icon(p.valide ? Icons.check_circle_rounded : Icons.pending_rounded, color: p.valide ? AppTheme.success : AppTheme.warning, size: 16),
        ],
      ),
    );
  }

  Widget _buildPointJournalier() {
    return _PointJournalierForm(
      onSoumis: () => setState(() => _navIndex = 0),
    );
  }

  Widget _buildHistorique() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final points = provider.mesPointsJournaliers;
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(title: const Text('Mon Historique'), backgroundColor: AppTheme.primaryDark),
          body: points.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 56, color: AppTheme.textHint.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text('Aucun point soumis', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: points.length,
                  itemBuilder: (ctx, i) => _buildHistoriqueCard(points[i], provider),
                ),
        );
      },
    );
  }

  Widget _buildHistoriqueCard(PointJournalier p, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.valide ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.dateFormatee, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (p.valide ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.valide ? 'Validé' : 'En attente', style: TextStyle(color: p.valide ? AppTheme.success : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniOp('Espèces', p.montantEspeces, AppTheme.accentOrange, provider),
              _miniOp('MTN', p.soldeMTN, AppTheme.mtnYellow, provider),
              _miniOp('Moov', p.soldeMoov, AppTheme.moovBlue, provider),
              _miniOp('Celtiis', p.soldeCeltiis, AppTheme.celtiisRed, provider),
            ],
          ),
          const Divider(color: AppTheme.divider, height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(provider.formaterMontant(p.totalGeneral), style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniOp(String label, double montant, Color color, AppProvider provider) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
          Text('${(montant / 1000).toStringAsFixed(0)}K', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PointJournalierForm extends StatefulWidget {
  final VoidCallback onSoumis;
  const _PointJournalierForm({required this.onSoumis});

  @override
  State<_PointJournalierForm> createState() => _PointJournalierFormState();
}

class _PointJournalierFormState extends State<_PointJournalierForm> {
  final _formKey = GlobalKey<FormState>();
  final _especesCtrl = TextEditingController();
  final _mtnCtrl = TextEditingController();
  final _moovCtrl = TextEditingController();
  final _celtiisCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  @override
  void dispose() {
    _especesCtrl.dispose();
    _mtnCtrl.dispose();
    _moovCtrl.dispose();
    _celtiisCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _total {
    return (double.tryParse(_especesCtrl.text) ?? 0) +
        (double.tryParse(_mtnCtrl.text) ?? 0) +
        (double.tryParse(_moovCtrl.text) ?? 0) +
        (double.tryParse(_celtiisCtrl.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final user = provider.utilisateurConnecte!;
        final pointExistant = provider.getPointDuJour(user.id);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Point Journalier'),
            backgroundColor: AppTheme.primaryDark,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entête date
                  _buildDateHeader(),
                  const SizedBox(height: 20),
                  if (pointExistant != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_rounded, color: AppTheme.warning, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Un point a déjà été soumis aujourd\'hui. Modification possible.', style: TextStyle(color: AppTheme.warning, fontSize: 12))),
                        ],
                      ),
                    ),
                  // Champs de saisie
                  _buildSection('Montant Espèces', Icons.payments_rounded, AppTheme.accentOrange),
                  _buildChampMontant(_especesCtrl, 'Montant en espèces (FCFA)', AppTheme.accentOrange),
                  const SizedBox(height: 20),
                  _buildSection('Soldes SIM', Icons.sim_card_rounded, AppTheme.textSecondary),
                  _buildChampOperateur('SIM MTN', _mtnCtrl, AppTheme.mtnYellow),
                  const SizedBox(height: 12),
                  _buildChampOperateur('SIM Moov', _moovCtrl, AppTheme.moovBlue),
                  const SizedBox(height: 12),
                  _buildChampOperateur('SIM Celtiis', _celtiisCtrl, AppTheme.celtiisRed),
                  const SizedBox(height: 20),
                  // Observations
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observations (optionnel)',
                      prefixIcon: Icon(Icons.note_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Total calculé
                  _buildTotalCalcule(provider),
                  const SizedBox(height: 20),
                  // Bouton soumettre
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _soumettre(provider, user.id),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('SOUMETTRE LE POINT'),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final mois = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: AppTheme.accentOrange, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Text('Saisie du point journalier', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String titre, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(titre, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChampMontant(TextEditingController ctrl, String label, Color color) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.attach_money_rounded, color: color),
        suffixText: 'FCFA',
        suffixStyle: const TextStyle(color: AppTheme.textHint),
      ),
    );
  }

  Widget _buildChampOperateur(String label, TextEditingController ctrl, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          prefixIcon: Icon(Icons.sim_card_rounded, color: color),
          suffixText: 'FCFA',
          suffixStyle: const TextStyle(color: AppTheme.textHint),
          filled: true,
          fillColor: color.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
        ),
      ),
    );
  }

  Widget _buildTotalCalcule(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(child: Text('Total calculé', style: TextStyle(color: Colors.white70, fontSize: 14))),
          Text(provider.formaterMontant(_total), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _soumettre(AppProvider provider, String agentId) {
    final point = PointJournalier(
      id: 'pj_${DateTime.now().millisecondsSinceEpoch}',
      agentId: agentId,
      gestionnaireId: provider.utilisateurConnecte!.gestionnaireId ?? '',
      date: DateTime.now(),
      montantEspeces: double.tryParse(_especesCtrl.text) ?? 0,
      soldeMTN: double.tryParse(_mtnCtrl.text) ?? 0,
      soldeMoov: double.tryParse(_moovCtrl.text) ?? 0,
      soldeCeltiis: double.tryParse(_celtiisCtrl.text) ?? 0,
      observations: _obsCtrl.text.isNotEmpty ? _obsCtrl.text : null,
    );

    provider.sauvegarderPoint(point);
    widget.onSoumis();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Point soumis — Total: ${provider.formaterMontant(point.totalGeneral)}'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
