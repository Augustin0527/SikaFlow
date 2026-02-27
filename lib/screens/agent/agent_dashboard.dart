import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/stand_model.dart';
import '../../models/operation_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';
import 'saisie_operation_screen.dart';
import 'demande_reequilibrage_screen.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      if (p.standActuel != null) {
        p.chargerOperationsStand(p.standActuel!.id, limite: 20);
      }
    });
  }

  String _fmt2(double v) => '${_fmt.format(v)} FCFA';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final user   = p.utilisateurConnecte!;
      final stand  = p.standActuel;
      final ent    = p.entrepriseActive;
      final alertes = p.alertesNonLues;

      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour ${user.prenom} 👋',
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              if (stand != null)
                Text(stand.nom,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            if (alertes.isNotEmpty)
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => _voirAlertes(p),
                ),
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: AppTheme.error, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${alertes.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ),
              ]),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
              onPressed: () {
                p.seDeconnecter();
                // go_router redirige automatiquement via refreshListenable
              },
            ),
          ],
        ),
        body: stand == null
            ? _buildAucunStand()
            : RefreshIndicator(
                onRefresh: p.rafraichir,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildSoldesCards(stand, ent),
                    const SizedBox(height: 16),
                    _buildActionsRapides(stand, p),
                    const SizedBox(height: 20),
                    _buildDernieresOperations(p),
                  ]),
                ),
              ),
        floatingActionButton: stand == null
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppTheme.accentOrange,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Nouvelle opération',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _saisirOperation(stand, p),
              ),
      );
    });
  }

  // ── Aucun stand ───────────────────────────────────────────────────────────
  Widget _buildAucunStand() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_outlined,
                color: AppTheme.accentOrange, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Aucun stand assigné',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Votre gestionnaire doit vous affecter à un stand pour commencer les opérations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ]),
      ),
    );
  }

  // ── Cartes soldes ─────────────────────────────────────────────────────────
  Widget _buildSoldesCards(StandModel stand, EntrepriseModel? ent) {
    return Column(children: [
      // Espèces
      _buildSoldeCard(
        icon: Icons.payments_outlined,
        label: 'Espèces disponibles',
        valeur: stand.soldeEspeces,
        couleur: _couleurSolde(
          stand.soldeEspeces,
          ent?.seuilAlerteEspeces ?? 50000,
          ent?.seuilCritiqueEspeces ?? 20000,
        ),
      ),
      const SizedBox(height: 10),
      // SIMs
      Row(children: Operateur.values.map((op) {
        final solde = stand.soldeSim(op.code);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSimCard(op, solde, ent),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildSoldeCard({
    required IconData icon,
    required String label,
    required double valeur,
    required Color couleur,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1), shape: BoxShape.circle,
          ),
          child: Icon(icon, color: couleur, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_fmt2(valeur),
              style: TextStyle(
                  color: couleur, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildSimCard(Operateur op, double solde, EntrepriseModel? ent) {
    final couleur = _couleurSolde(
      solde,
      ent?.seuilAlerteSim ?? 30000,
      ent?.seuilCritiqueSim ?? 10000,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(op.couleurHex).withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Text(op.code,
            style: TextStyle(
                color: Color(op.couleurHex),
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Text(_fmt2(solde),
            style: TextStyle(color: couleur, fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Color _couleurSolde(double val, double seuilAlerte, double seuilCritique) {
    if (val <= seuilCritique) return AppTheme.error;
    if (val <= seuilAlerte) return Colors.orange;
    return AppTheme.success;
  }

  // ── Actions rapides ───────────────────────────────────────────────────────
  Widget _buildActionsRapides(StandModel stand, AppProvider p) {
    return Row(children: [
      Expanded(
        child: _buildActionBtn(
          icon: Icons.swap_horiz_rounded,
          label: 'Rééquilibrer',
          couleur: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>
                DemandeReequilibrageScreen(stand: stand)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildActionBtn(
          icon: Icons.history_rounded,
          label: 'Historique',
          couleur: Colors.purple,
          onTap: () => _voirHistorique(p),
        ),
      ),
    ]);
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: couleur, size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: couleur, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Dernières opérations ──────────────────────────────────────────────────
  Widget _buildDernieresOperations(AppProvider p) {
    final ops = p.operations.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dernières opérations',
                style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (ops.isNotEmpty)
              TextButton(
                onPressed: () => _voirHistorique(p),
                child: const Text('Tout voir',
                    style: TextStyle(color: AppTheme.accentOrange)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (ops.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Aucune opération aujourd\'hui',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          )
        else
          ...ops.map((op) => _buildOperationTile(op)),
      ],
    );
  }

  Widget _buildOperationTile(OperationModel op) {
    final type = op.typeEnum;
    final operateur = op.operateurEnum;
    final isPositif = op.impactEspeces > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Color(operateur.couleurHex).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(type.emoji,
                style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(type.label,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(operateur.couleurHex).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(operateur.code,
                    style: TextStyle(
                        color: Color(operateur.couleurHex), fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(DateFormat('HH:mm').format(op.dateHeure),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmt2(op.montant),
              style: TextStyle(
                color: isPositif ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )),
          if (op.ristourneCalculee > 0)
            Text('+${_fmt.format(op.ristourneCalculee)} FCFA',
                style: const TextStyle(
                    color: Colors.amber, fontSize: 10)),
        ]),
      ]),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _saisirOperation(StandModel stand, AppProvider p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaisieOperationScreen(stand: stand)),
    ).then((_) {
      if (mounted) p.chargerOperationsStand(stand.id, limite: 20);
    });
  }

  void _voirHistorique(AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.history, color: AppTheme.accentOrange),
              SizedBox(width: 10),
              Text('Historique des opérations',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          const Divider(color: AppTheme.divider),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.operations.length,
              itemBuilder: (_, i) => _buildOperationTile(p.operations[i]),
            ),
          ),
        ]),
      ),
    );
  }

  void _voirAlertes(AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Alertes',
                style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        ...p.alertesNonLues.map((a) => ListTile(
          leading: Icon(
            a.estCritique ? Icons.error_rounded : Icons.warning_amber_rounded,
            color: a.estCritique ? AppTheme.error : Colors.orange,
          ),
          title: Text(_labelAlerte(a.type, a.operateur),
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            'Solde actuel : ${_fmt2(a.montantActuel)} / Seuil : ${_fmt2(a.seuil)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () {
              p.marquerAlerteLue(a.id);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  String _labelAlerte(String type, String? op) {
    switch (type) {
      case 'especes_basse':    return 'Espèces en baisse — stand ${op ?? ''}';
      case 'especes_critique': return '⚠️ Espèces critiques — stand ${op ?? ''}';
      case 'sim_basse':        return 'Solde SIM $op en baisse';
      case 'sim_critique':     return '⚠️ Solde SIM $op critique';
      default:                 return type;
    }
  }
}
