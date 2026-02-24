import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/retrait.dart';

class RetraitsScreen extends StatefulWidget {
  const RetraitsScreen({super.key});

  @override
  State<RetraitsScreen> createState() => _RetraitsScreenState();
}

class _RetraitsScreenState extends State<RetraitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Retraits'),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final retraits = provider.mesRetraits;
          return Column(
            children: [
              // Boutons d'action
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBoutonRetrait(
                      context,
                      'Retrait Espèces',
                      'Retirer des espèces auprès d\'un agent',
                      Icons.payments_rounded,
                      AppTheme.accentOrange,
                      () => _dialogRetraitEspeces(context, provider),
                    ),
                    const SizedBox(height: 12),
                    _buildBoutonRetrait(
                      context,
                      'Retrait Ristournes SIM',
                      'Retirer les ristournes depuis les SIM',
                      Icons.star_rounded,
                      AppTheme.success,
                      () => _dialogRetraitRistourne(context, provider),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.divider),
              // Historique
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Historique des retraits', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: retraits.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: retraits.length,
                        itemBuilder: (ctx, i) => _buildRetraitCard(retraits[i], provider),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoutonRetrait(BuildContext context, String titre, String sous, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sous, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRetraitCard(Retrait retrait, AppProvider provider) {
    final agent = provider.getUtilisateurParId(retrait.agentId);
    final color = retrait.estRistourne ? AppTheme.success : AppTheme.accentOrange;
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(retrait.estRistourne ? Icons.star_rounded : Icons.payments_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(retrait.typeLibelle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Agent: ${agent?.nomComplet ?? retrait.agentId}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(retrait.dateFormatee, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text(
            provider.formaterMontant(retrait.montant),
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 56, color: AppTheme.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('Aucun retrait effectué', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  void _dialogRetraitEspeces(BuildContext context, AppProvider provider) {
    final montantCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String? agentSelectionne;
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
                const Text('Retrait Espèces', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: agentSelectionne,
                  dropdownColor: AppTheme.cardDarker,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Sélectionner un agent', prefixIcon: Icon(Icons.person)),
                  items: provider.mesAgents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nomComplet))).toList(),
                  onChanged: (v) => setModalState(() => agentSelectionne = v),
                  validator: (v) => v == null ? 'Choisir un agent' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.payments)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Entrez un montant';
                    if (double.tryParse(v) == null) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: motifCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Motif (optionnel)', prefixIcon: Icon(Icons.note)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final retrait = Retrait(
                        id: provider.genererNouvelId(),
                        gestionnaireId: provider.utilisateurConnecte!.id,
                        agentId: agentSelectionne!,
                        type: 'especes',
                        montant: double.parse(montantCtrl.text),
                        date: DateTime.now(),
                        motif: motifCtrl.text.isNotEmpty ? motifCtrl.text : null,
                      );
                      provider.effectuerRetrait(retrait);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Retrait de ${provider.formaterMontant(retrait.montant)} enregistré !'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: const Text('CONFIRMER LE RETRAIT'),
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

  void _dialogRetraitRistourne(BuildContext context, AppProvider provider) {
    final disponibles = provider.ristournesDisponibles;
    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune ristourne disponible à retirer'), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Retrait Ristournes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${disponibles.length} ristourne(s) disponible(s)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: disponibles.length,
                itemBuilder: (ctx, i) {
                  final r = disponibles[i];
                  final agent = provider.getUtilisateurParId(r.agentId);
                  final color = r.operateur == 'MTN' ? AppTheme.mtnYellow : r.operateur == 'Moov' ? AppTheme.moovBlue : AppTheme.celtiisRed;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDarker,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 10, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.operateur} — ${agent?.nomComplet ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(r.dateFormatee, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(provider.formaterMontant(r.montant), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                final retrait = Retrait(
                                  id: provider.genererNouvelId(),
                                  gestionnaireId: provider.utilisateurConnecte!.id,
                                  agentId: r.agentId,
                                  type: 'ristourne_${r.operateur.toLowerCase()}',
                                  montant: r.montant,
                                  date: DateTime.now(),
                                  ristourneId: r.id,
                                );
                                provider.effectuerRetrait(retrait);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ristourne ${r.operateur} retirée !'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Retirer', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
