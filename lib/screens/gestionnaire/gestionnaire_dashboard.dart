import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/operateur_card.dart';
import 'retraits_screen.dart';
import 'membres_screen.dart';
import '../controleur/ristournes_screen.dart';
import 'rapports_screen.dart';
import '../auth/changer_mdp_screen.dart';

class GestionnaireDashboard extends StatefulWidget {
  const GestionnaireDashboard({super.key});

  @override
  State<GestionnaireDashboard> createState() => _GestionnaireDashboardState();
}

class _GestionnaireDashboardState extends State<GestionnaireDashboard> {
  int _selectedPeriode = 0; // 0=semaine, 1=mois, 2=année
  int _navIndex = 0;
  final List<String> _periodes = ['semaine', 'mois', 'annee'];
  final List<String> _periodesLabels = ['Semaine', 'Mois', 'Année'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildDashboard(),
          const MembresScreen(),
          const RistournesScreen(),
          const RetraitsScreen(),
          const RapportsGestScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tableau'),
            BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Membres'),
            BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Ristournes'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Retraits'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Rapports'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final synth = provider.syntheseAujourdhui;
        final user = provider.utilisateurConnecte!;
        final donnees = provider.getDonneesEvolution(_periodes[_selectedPeriode]);

        return CustomScrollView(
          slivers: [
            _buildAppBar(user, provider),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Carte synthèse principale
                  _buildSyntheseCard(synth, provider),
                  const SizedBox(height: 16),
                  // Cartes opérateurs
                  _buildOperateursSection(synth, provider),
                  const SizedBox(height: 16),
                  // Graphique évolution
                  _buildEvolutionSection(donnees, provider),
                  const SizedBox(height: 16),
                  // Ristournes disponibles
                  _buildRistournesSection(provider),
                  const SizedBox(height: 16),
                  // Accès rapide retraits
                  _buildActionsRapides(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(user, AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bonjour, ${user.prenom} !',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      provider.entrepriseActive?.nom ?? 'Gestionnaire',
                      style: const TextStyle(color: AppTheme.accentOrange, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                onPressed: () => _confirmerDeconnexion(provider),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                color: AppTheme.cardDarker,
                onSelected: (v) {
                  if (v == 'mdp') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangerMotDePasseScreen()));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'mdp', child: Row(children: [Icon(Icons.lock_reset_rounded, color: AppTheme.accentOrange, size: 18), SizedBox(width: 8), Text('Changer mot de passe', style: TextStyle(color: Colors.white, fontSize: 13))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyntheseCard(Map<String, double> synth, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Synthèse du jour', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            provider.formaterMontant(synth['total'] ?? 0),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Total général (espèces + SIM)',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _smallStatItem(
                  'Espèces',
                  provider.formaterMontant(synth['especes'] ?? 0),
                  Icons.payments_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _smallStatItem(
                  'Total SIM',
                  provider.formaterMontant((synth['mtn'] ?? 0) + (synth['moov'] ?? 0) + (synth['celtiis'] ?? 0)),
                  Icons.sim_card_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _smallStatItem(
                  'Agents actifs',
                  '${provider.mesAgents.length}',
                  Icons.group_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStatItem(String label, String valeur, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }

  Widget _buildOperateursSection(Map<String, double> synth, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Soldes par opérateur', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OperateurCard(nom: 'MTN', montant: synth['mtn'] ?? 0, gradient: AppTheme.mtnGradient, icon: 'MTN', provider: provider)),
            const SizedBox(width: 10),
            Expanded(child: OperateurCard(nom: 'Moov', montant: synth['moov'] ?? 0, gradient: AppTheme.moovGradient, icon: 'Moov', provider: provider)),
            const SizedBox(width: 10),
            Expanded(child: OperateurCard(nom: 'Celtiis', montant: synth['celtiis'] ?? 0, gradient: AppTheme.celtiisGradient, icon: 'Celtiis', provider: provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildEvolutionSection(List<Map<String, dynamic>> donnees, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Évolution des flux', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...List.generate(_periodesLabels.length, (i) => GestureDetector(
                onTap: () => setState(() => _selectedPeriode = i),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _selectedPeriode == i ? AppTheme.accentOrange : AppTheme.cardDarker,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _periodesLabels[i],
                    style: TextStyle(
                      color: _selectedPeriode == i ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: donnees.isEmpty
                ? const Center(child: Text('Aucune donnée', style: TextStyle(color: AppTheme.textHint)))
                : _buildLineChart(donnees),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> donnees) {
    final maxVal = donnees.map((d) => d['valeur'] as double).reduce((a, b) => a > b ? a : b);
    final spots = donnees.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['valeur'] as double)).toList();

    int skipLabel = 1;
    if (_selectedPeriode == 1) skipLabel = 4;
    if (_selectedPeriode == 2) skipLabel = 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: skipLabel.toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < donnees.length && idx % skipLabel == 0) {
                  return Text(
                    donnees[idx]['label'] as String,
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [AppTheme.accentOrange, AppTheme.accentOrangeLight]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.accentOrange.withValues(alpha: 0.3),
                  AppTheme.accentOrange.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: (donnees.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal * 1.2,
      ),
    );
  }

  Widget _buildRistournesSection(AppProvider provider) {
    final dispo = provider.ristournesDisponibles;
    final total = provider.totalRistournesDisponibles;

    return GestureDetector(
      onTap: () => setState(() => _navIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded, color: AppTheme.success, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ristournes disponibles', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    provider.formaterMontant(total),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('${dispo.length} ristourne(s) non retirée(s)', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRapides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                'Retrait Espèces',
                Icons.payments_rounded,
                AppTheme.accentOrange,
                () => setState(() => _navIndex = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                'Retrait Ristourne',
                Icons.star_rounded,
                AppTheme.success,
                () => setState(() => _navIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerDeconnexion(AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Voulez-vous vous déconnecter ?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.seDeconnecter();
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}
