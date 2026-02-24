import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'ristournes_screen.dart';
import '../auth/changer_mdp_screen.dart';

class ControleurDashboard extends StatefulWidget {
  const ControleurDashboard({super.key});

  @override
  State<ControleurDashboard> createState() => _ControleurDashboardState();
}

class _ControleurDashboardState extends State<ControleurDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildAccueil(),
          _buildRistournesTab(),
          _buildValidation(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppTheme.primaryDark),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Ristournes'),
              BottomNavigationBarItem(icon: Icon(Icons.verified_rounded), label: 'Validation'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccueil() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final user = provider.utilisateurConnecte!;
        final points = provider.mesPointsJournaliers;
        final enAttente = points.where((p) => !p.valide).length;
        final valides = points.where((p) => p.valide).length;
        final ristournes = provider.mesRistournes;
        final ristournesTotalDispo = provider.totalRistournesDisponibles;

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
                        decoration: BoxDecoration(color: AppTheme.moovBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.verified_user_rounded, color: AppTheme.moovBlue, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user.nomComplet, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Contrôleur', style: TextStyle(color: AppTheme.moovBlue, fontSize: 12)),
                          ],
                        ),
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
                  // Stats rapides
                  Row(
                    children: [
                      Expanded(child: _statCard('En attente', '$enAttente', Icons.pending_rounded, AppTheme.warning)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Validés', '$valides', Icons.check_circle_rounded, AppTheme.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Ristournes', '${ristournes.length}', Icons.star_rounded, AppTheme.accentOrange)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Ristournes dispo
                  _buildRistournesDispoCard(provider.formaterMontant(ristournesTotalDispo), provider.ristournesDisponibles.length),
                  const SizedBox(height: 16),
                  // Points récents à valider
                  _buildPointsAValider(provider),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String titre, String valeur, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(titre, style: const TextStyle(color: AppTheme.textHint, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRistournesDispoCard(String montant, int nb) {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.success.withValues(alpha: 0.15), AppTheme.success.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.success, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ristournes disponibles', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(montant, style: const TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$nb ristourne(s) non retirée(s)', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.success),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsAValider(AppProvider provider) {
    final points = provider.mesPointsJournaliers.where((p) => !p.valide).take(5).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Points à valider', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => setState(() => _navIndex = 2),
                child: const Text('Voir tout', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map((p) {
            final agent = provider.getUtilisateurParId(p.agentId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.pending_rounded, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${agent?.nomComplet ?? ''} — ${p.dateFormatee}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                  Text(provider.formaterMontant(p.totalGeneral), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRistournesTab() {
    return const RistournesScreen();
  }

  Widget _buildValidation() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final points = provider.mesPointsJournaliers.where((p) => !p.valide).toList();
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(title: const Text('Validation des points'), backgroundColor: AppTheme.primaryDark),
          body: points.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 60, color: AppTheme.success),
                      const SizedBox(height: 12),
                      const Text('Tous les points sont validés !', style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: points.length,
                  itemBuilder: (ctx, i) => _buildPointCard(points[i], provider),
                ),
        );
      },
    );
  }

  Widget _buildPointCard(point, AppProvider provider) {
    final agent = provider.getUtilisateurParId(point.agentId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded, color: AppTheme.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent?.nomComplet ?? point.agentId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(point.dateFormatee, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              ),
              Text(provider.formaterMontant(point.totalGeneral), style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _detailOp('MTN', point.soldeMTN, AppTheme.mtnYellow, provider),
              _detailOp('Moov', point.soldeMoov, AppTheme.moovBlue, provider),
              _detailOp('Celtiis', point.soldeCeltiis, AppTheme.celtiisRed, provider),
              _detailOp('Cash', point.montantEspeces, AppTheme.accentOrange, provider),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                point.valide = true;
                point.validateurId = provider.utilisateurConnecte!.id;
                point.dateValidation = DateTime.now();
                provider.sauvegarderPoint(point);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Point de ${agent?.nomComplet ?? ''} validé !'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('VALIDER CE POINT'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailOp(String label, double montant, Color color, AppProvider provider) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
          Text('${(montant / 1000).toStringAsFixed(0)}K', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
