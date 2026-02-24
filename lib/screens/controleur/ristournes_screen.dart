import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/ristourne.dart';

class RistournesScreen extends StatefulWidget {
  const RistournesScreen({super.key});

  @override
  State<RistournesScreen> createState() => _RistournesScreenState();
}

class _RistournesScreenState extends State<RistournesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filtreOperateur = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
        title: const Text('Ristournes'),
        backgroundColor: AppTheme.primaryDark,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentOrange,
          labelColor: AppTheme.accentOrange,
          unselectedLabelColor: AppTheme.textHint,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Historique'),
          ],
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (ctx, provider, _) {
              if (provider.utilisateurConnecte?.role == 'controleur') {
                return IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppTheme.accentOrange),
                  onPressed: () => _ajouterRistourne(context, provider),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDisponibles(),
          _buildHistorique(),
        ],
      ),
    );
  }

  Widget _buildDisponibles() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final disponibles = provider.ristournesDisponibles;
        final total = provider.totalRistournesDisponibles;

        return Column(
          children: [
            // Total disponible
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.success.withValues(alpha: 0.2), AppTheme.success.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.success, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total ristournes disponibles', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(provider.formaterMontant(total), style: const TextStyle(color: AppTheme.success, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            // Filtre opérateur
            _buildFiltreOperateur(),
            // Liste
            Expanded(
              child: disponibles.isEmpty
                  ? _buildEmpty('Aucune ristourne disponible', Icons.star_border_rounded)
                  : _buildListeRistournes(disponibles.where((r) => _filtreOperateur == 'Tous' || r.operateur == _filtreOperateur).toList(), provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorique() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final toutes = provider.mesRistournes;
        final filtrees = _filtreOperateur == 'Tous' ? toutes : toutes.where((r) => r.operateur == _filtreOperateur).toList();
        return Column(
          children: [
            _buildFiltreOperateur(),
            Expanded(
              child: filtrees.isEmpty
                  ? _buildEmpty('Aucune ristourne enregistrée', Icons.history_rounded)
                  : _buildListeRistournes(filtrees, provider, showStatut: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltreOperateur() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Tous', 'MTN', 'Moov', 'Celtiis'].map((op) {
          final sel = _filtreOperateur == op;
          Color color = AppTheme.textSecondary;
          if (op == 'MTN') color = AppTheme.mtnYellow;
          if (op == 'Moov') color = AppTheme.moovBlue;
          if (op == 'Celtiis') color = AppTheme.celtiisRed;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filtreOperateur = op),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: 0.2) : AppTheme.cardDarker,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? color : AppTheme.divider),
                ),
                child: Text(op, style: TextStyle(color: sel ? color : AppTheme.textHint, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListeRistournes(List<Ristourne> ristournes, AppProvider provider, {bool showStatut = false}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ristournes.length,
      itemBuilder: (ctx, i) {
        final r = ristournes[i];
        final agent = provider.getUtilisateurParId(r.agentId);
        final color = r.operateur == 'MTN' ? AppTheme.mtnYellow : r.operateur == 'Moov' ? AppTheme.moovBlue : AppTheme.celtiisRed;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(r.operateur, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(agent?.nomComplet ?? r.agentId, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.dateFormatee, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                    if (r.observations != null)
                      Text(r.observations!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(provider.formaterMontant(r.montant), style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
                  if (showStatut) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (r.retiree ? AppTheme.textHint : AppTheme.success).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.retiree ? 'Retirée' : 'Disponible', style: TextStyle(color: r.retiree ? AppTheme.textHint : AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppTheme.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  void _ajouterRistourne(BuildContext context, AppProvider provider) {
    final montantCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    String? agentSelectionne;
    String operateurSelectionne = 'MTN';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter une Ristourne', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Sélection agent
                DropdownButtonFormField<String>(
                  initialValue: agentSelectionne,
                  dropdownColor: AppTheme.cardDarker,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Agent', prefixIcon: Icon(Icons.person_rounded)),
                  items: provider.mesAgents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nomComplet))).toList(),
                  onChanged: (v) => setModalState(() => agentSelectionne = v),
                  validator: (v) => v == null ? 'Choisir un agent' : null,
                ),
                const SizedBox(height: 12),
                // Sélection opérateur
                const Text('Opérateur', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: ['MTN', 'Moov', 'Celtiis'].map((op) {
                    final sel = operateurSelectionne == op;
                    final color = op == 'MTN' ? AppTheme.mtnYellow : op == 'Moov' ? AppTheme.moovBlue : AppTheme.celtiisRed;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => operateurSelectionne = op),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? color.withValues(alpha: 0.2) : AppTheme.cardDarker,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? color : AppTheme.divider, width: sel ? 2 : 1),
                          ),
                          child: Text(op, style: TextStyle(color: sel ? color : AppTheme.textHint, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Montant
                TextFormField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.star_rounded)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Entrez un montant';
                    if (double.tryParse(v) == null) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Observations
                TextFormField(
                  controller: obsCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Observations (optionnel)', prefixIcon: Icon(Icons.note_rounded)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final ristourne = Ristourne(
                        id: provider.genererNouvelId(),
                        agentId: agentSelectionne!,
                        gestionnaireId: provider.utilisateurConnecte!.gestionnaireId ?? '',
                        operateur: operateurSelectionne,
                        montant: double.parse(montantCtrl.text),
                        date: DateTime.now(),
                        controleurId: provider.utilisateurConnecte!.id,
                        observations: obsCtrl.text.isNotEmpty ? obsCtrl.text : null,
                      );
                      provider.ajouterRistourne(ristourne);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ristourne $operateurSelectionne de ${provider.formaterMontant(ristourne.montant)} ajoutée !'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('ENREGISTRER LA RISTOURNE'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
