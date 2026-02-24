import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class RapportsGestScreen extends StatefulWidget {
  const RapportsGestScreen({super.key});

  @override
  State<RapportsGestScreen> createState() => _RapportsGestScreenState();
}

class _RapportsGestScreenState extends State<RapportsGestScreen> {
  String _periodeSelectionnee = 'semaine';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Rapports'), backgroundColor: AppTheme.primaryDark),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final points = provider.mesPointsJournaliers;
          final retraits = provider.mesRetraits;
          final totalRetraits = retraits.fold(0.0, (s, r) => s + r.montant);
          final totalRistournes = provider.totalRistournesDisponibles;
          final donnees = provider.getDonneesEvolution(_periodeSelectionnee);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur de période
                _buildPeriodeSelector(),
                const SizedBox(height: 16),
                // Stats résumé
                _buildStatsResume(provider, points, totalRetraits, totalRistournes),
                const SizedBox(height: 16),
                // Graphique barres par opérateur
                _buildGraphiqueOperateurs(donnees, provider),
                const SizedBox(height: 16),
                // Performance par agent
                _buildPerformanceAgents(provider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodeSelector() {
    return Row(
      children: [
        _periodeChip('semaine', 'Cette semaine'),
        const SizedBox(width: 8),
        _periodeChip('mois', 'Ce mois'),
        const SizedBox(width: 8),
        _periodeChip('annee', 'Cette année'),
      ],
    );
  }

  Widget _periodeChip(String val, String label) {
    final sel = _periodeSelectionnee == val;
    return GestureDetector(
      onTap: () => setState(() => _periodeSelectionnee = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppTheme.accentOrange : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppTheme.accentOrange : AppTheme.divider),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildStatsResume(AppProvider provider, points, double totalRetraits, double totalRistournes) {
    final totalOps = points.fold(0.0, (s, p) => s + p.totalGeneral);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('Total Opérations', provider.formaterMontant(totalOps), Icons.account_balance_wallet_rounded, AppTheme.accentOrange),
        _statCard('Total Retraits', provider.formaterMontant(totalRetraits), Icons.payments_rounded, AppTheme.warning),
        _statCard('Ristournes Dispo', provider.formaterMontant(totalRistournes), Icons.star_rounded, AppTheme.success),
        _statCard('Nb. de points', '${points.length}', Icons.receipt_long_rounded, AppTheme.moovBlue),
      ],
    );
  }

  Widget _statCard(String titre, String valeur, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valeur, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(titre, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphiqueOperateurs(List<Map<String, dynamic>> donnees, AppProvider provider) {
    final points = provider.mesPointsJournaliers;
    double totalMTN = points.fold(0.0, (s, p) => s + p.soldeMTN);
    double totalMoov = points.fold(0.0, (s, p) => s + p.soldeMoov);
    double totalCeltiis = points.fold(0.0, (s, p) => s + p.soldeCeltiis);
    double total = totalMTN + totalMoov + totalCeltiis;
    if (total == 0) total = 1;

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
          const Text('Répartition par opérateur', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: totalMTN, color: AppTheme.mtnYellow, title: '${(totalMTN / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                      PieChartSectionData(value: totalMoov, color: AppTheme.moovBlue, title: '${(totalMoov / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(value: totalCeltiis, color: AppTheme.celtiisRed, title: '${(totalCeltiis / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _legendeItem('MTN', totalMTN, AppTheme.mtnYellow, provider),
                    const SizedBox(height: 8),
                    _legendeItem('Moov', totalMoov, AppTheme.moovBlue, provider),
                    const SizedBox(height: 8),
                    _legendeItem('Celtiis', totalCeltiis, AppTheme.celtiisRed, provider),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendeItem(String nom, double montant, Color color, AppProvider provider) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(provider.formaterMontant(montant), style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceAgents(AppProvider provider) {
    final agents = provider.mesAgents;
    if (agents.isEmpty) return const SizedBox.shrink();

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
          const Text('Performance par agent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...agents.map((agent) {
            final points = provider.pointsJournaliers.where((p) => p.agentId == agent.id).toList();
            final total = points.fold(0.0, (s, p) => s + p.totalGeneral);
            final nbPoints = points.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${agent.prenom[0]}${agent.nom[0]}', style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agent.nomComplet, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('$nbPoints point(s)', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(provider.formaterMontant(total), style: const TextStyle(color: AppTheme.accentOrange, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
