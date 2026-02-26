import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/stand_model.dart';
import '../../models/operation_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';

class StandsScreen extends StatelessWidget {
  const StandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final stands = p.standsActifs;
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: stands.isEmpty
            ? _buildVide(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stands.length,
                itemBuilder: (_, i) =>
                    _StandCard(stand: stands[i]),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.accentOrange,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouveau stand',
              style: TextStyle(color: Colors.white)),
          onPressed: () => _creerStand(context, p),
        ),
      );
    });
  }

  Widget _buildVide(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.store_outlined,
            color: AppTheme.accentOrange, size: 60),
        const SizedBox(height: 16),
        const Text('Aucun stand',
            style: TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Créez vos stands pour commencer à gérer vos opérations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary)),
      ]),
    );
  }

  void _creerStand(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreerStandSheet(),
    );
  }
}

class _StandCard extends StatelessWidget {
  final StandModel stand;
  const _StandCard({required this.stand});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    String fmt2(double v) => '${fmt.format(v)} FCFA';
    final p = context.watch<AppProvider>();
    final agents = p.agents;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppTheme.accentOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stand.nom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(stand.lieu,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ),
            PopupMenuButton<String>(
              color: AppTheme.cardDark,
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textSecondary),
              onSelected: (v) => _action(context, v, p, agents),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'affecter',
                    child: Row(children: [
                      Icon(Icons.person_add_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Affecter un agent',
                          style: TextStyle(color: Colors.white)),
                    ])),
                const PopupMenuItem(
                    value: 'capital',
                    child: Row(children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Ajuster capital',
                          style: TextStyle(color: Colors.white)),
                    ])),
                const PopupMenuItem(
                    value: 'historique',
                    child: Row(children: [
                      Icon(Icons.history, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Historique agents',
                          style: TextStyle(color: Colors.white)),
                    ])),
              ],
            ),
          ]),
        ),

        // Agent actuel
        if (stand.agentActuelNom != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.person_outline,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Text(stand.agentActuelNom!,
                    style: const TextStyle(
                        color: AppTheme.success, fontSize: 13)),
                const Spacer(),
                if (stand.dateAffectationAgent != null)
                  Text(
                    'depuis ${DateFormat('dd/MM/yyyy').format(stand.dateAffectationAgent!)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
              ]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.person_off_outlined,
                    color: AppTheme.error, size: 16),
                SizedBox(width: 8),
                Text('Aucun agent affecté',
                    style: TextStyle(color: AppTheme.error, fontSize: 13)),
              ]),
            ),
          ),

        const SizedBox(height: 12),

        // Soldes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildSolde('Espèces', stand.soldeEspeces, Colors.white, fmt2),
              ),
              ...Operateur.values.map((op) => Expanded(
                child: _buildSolde(op.code, stand.soldeSim(op.code),
                    Color(op.couleurHex), fmt2),
              )),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildSolde(String label, double val, Color color,
      String Function(double) fmt2) {
    return Column(children: [
      Text(label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
      const SizedBox(height: 3),
      Text(fmt2(val),
          style: TextStyle(color: color,
              fontWeight: FontWeight.bold, fontSize: 11),
          overflow: TextOverflow.ellipsis),
    ]);
  }

  void _action(BuildContext context, String action, AppProvider p,
      List agents) {
    switch (action) {
      case 'affecter':
        _affecterAgent(context, p, agents);
        break;
      case 'capital':
        _ajusterCapital(context, p);
        break;
      case 'historique':
        _voirHistorique(context);
        break;
    }
  }

  void _affecterAgent(BuildContext context, AppProvider p, List agents) {
    if (agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun agent disponible. Créez des agents d\'abord.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Affecter un agent',
              style: TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...agents.map((agent) => ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0x1AFF6B00),
            child: Icon(Icons.person, color: AppTheme.accentOrange, size: 20),
          ),
          title: Text(agent.nomComplet,
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(agent.telephone,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          trailing: stand.agentActuelId == agent.id
              ? const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 18)
              : null,
          onTap: () async {
            Navigator.pop(context);
            final result = await p.affecterAgent(
              standId: stand.id, agentId: agent.id,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['success'] == true
                  ? '${agent.prenom} affecté au stand ${stand.nom}'
                  : result['erreur'] ?? 'Erreur'),
              backgroundColor: result['success'] == true
                  ? AppTheme.success
                  : AppTheme.error,
            ));
          },
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _ajusterCapital(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AjusterCapitalSheet(stand: stand),
    );
  }

  void _voirHistorique(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Historique des agents',
              style: TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...stand.historiqueAgents.reversed.map((h) => ListTile(
          leading: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
          title: Text(h.agentNom,
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            'Du ${DateFormat('dd/MM/yyyy').format(h.dateDebut)}'
            '${h.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(h.dateFin!)}' : ' — En poste'}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
          trailing: h.dateFin == null
              ? const Chip(
                  label: Text('Actuel',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: AppTheme.success,
                  padding: EdgeInsets.zero,
                )
              : null,
        )),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── Sheet créer stand ─────────────────────────────────────────────────────────
class _CreerStandSheet extends StatefulWidget {
  const _CreerStandSheet();

  @override
  State<_CreerStandSheet> createState() => _CreerStandSheetState();
}

class _CreerStandSheetState extends State<_CreerStandSheet> {
  final _nomCtrl      = TextEditingController();
  final _lieuCtrl     = TextEditingController();
  final _especeCtrl   = TextEditingController();

  // Numéros SIM et capitaux initiaux par opérateur
  final Map<String, TextEditingController> _numSimCtrl = {
    'MTN': TextEditingController(),
    'Moov': TextEditingController(),
    'Celtiis': TextEditingController(),
  };
  final Map<String, TextEditingController> _capitalSimCtrl = {
    'MTN': TextEditingController(),
    'Moov': TextEditingController(),
    'Celtiis': TextEditingController(),
  };

  bool _chargement = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _lieuCtrl.dispose();
    _especeCtrl.dispose();
    for (final c in _numSimCtrl.values) c.dispose();
    for (final c in _capitalSimCtrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 10,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Barre de drag
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Créer un stand',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Renseignez les informations et le capital initial.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // ── Infos générales ──
          _buildSectionTitle('Informations du stand'),
          const SizedBox(height: 10),
          _buildField(_nomCtrl, 'Nom du stand', 'Ex: Stand Zogbo 1'),
          const SizedBox(height: 10),
          _buildField(_lieuCtrl, 'Lieu', 'Ex: Marché Zogbo, Cotonou'),
          const SizedBox(height: 20),

          // ── Capital espèces ──
          _buildSectionTitle('Capital espèces initial'),
          const SizedBox(height: 10),
          _buildCapitalField(_especeCtrl, 'Montant espèces',
              Icons.payments_rounded, Colors.white),
          const SizedBox(height: 20),

          // ── SIM : numéro + capital ──
          _buildSectionTitle('SIMs — Numéro & Capital initial'),
          const SizedBox(height: 10),
          ...Operateur.values.map((op) {
            final couleur = Color(op.couleurHex);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: couleur.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(op.code,
                          style: TextStyle(
                              color: couleur,
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(op.nom,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    // Numéro SIM
                    Expanded(
                      child: TextField(
                        controller: _numSimCtrl[op.code],
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro SIM',
                          labelStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          prefixIcon: Icon(Icons.sim_card_outlined,
                              color: couleur, size: 18),
                          filled: true,
                          fillColor: AppTheme.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Capital SIM
                    Expanded(
                      child: TextField(
                        controller: _capitalSimCtrl[op.code],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Capital (FCFA)',
                          labelStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                              color: couleur, size: 18),
                          suffixText: 'FCFA',
                          suffixStyle: const TextStyle(
                              color: AppTheme.textHint, fontSize: 11),
                          filled: true,
                          fillColor: AppTheme.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            );
          }),

          // ── Récap capital ──
          _buildCapitalRecap(),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _chargement ? null : _creer,
              child: _chargement
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Créer le stand',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppTheme.accentOrange,
            fontWeight: FontWeight.bold, fontSize: 13));
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        filled: true, fillColor: AppTheme.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCapitalField(TextEditingController ctrl, String label,
      IconData icon, Color couleur) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: couleur, size: 20),
        suffixText: 'FCFA',
        suffixStyle: const TextStyle(color: AppTheme.textHint),
        filled: true, fillColor: AppTheme.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCapitalRecap() {
    final especes = double.tryParse(_especeCtrl.text) ?? 0;
    double totalSim = 0;
    for (final op in Operateur.values) {
      totalSim += double.tryParse(_capitalSimCtrl[op.code]?.text ?? '') ?? 0;
    }
    final total = especes + totalSim;
    if (total == 0) return const SizedBox.shrink();
    final fmt = (double v) =>
        v.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Récapitulatif capital',
              style: TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _recapLigne('Espèces', especes, Colors.white),
          ...Operateur.values.map((op) {
            final v = double.tryParse(_capitalSimCtrl[op.code]?.text ?? '') ?? 0;
            if (v == 0) return const SizedBox.shrink();
            return _recapLigne(op.code, v, Color(op.couleurHex));
          }),
          const Divider(color: AppTheme.divider, height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${fmt(total)} FCFA',
                style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ],
      ),
    );
  }

  Widget _recapLigne(String label, double v, Color couleur) {
    final fmt = (double val) =>
        val.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(color: couleur, fontSize: 12)),
        Text('${fmt(v)} FCFA',
            style: TextStyle(color: couleur, fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _creer() async {
    if (_nomCtrl.text.trim().isEmpty || _lieuCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le nom et le lieu sont obligatoires'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _chargement = true);

    // Construire les SIM avec capital initial
    final sims = Operateur.values.map((op) => SimCard(
      operateur: op.code,
      numero: _numSimCtrl[op.code]?.text.trim() ?? '',
      solde: double.tryParse(_capitalSimCtrl[op.code]?.text ?? '') ?? 0,
    )).toList();

    final capitalEspeces =
        double.tryParse(_especeCtrl.text) ?? 0;

    final p = context.read<AppProvider>();
    final result = await p.creerStand(
      nom: _nomCtrl.text.trim(),
      lieu: _lieuCtrl.text.trim(),
      sims: sims,
      capitalEspecesInitial: capitalEspeces,
    );
    if (!mounted) return;
    setState(() => _chargement = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? 'Stand créé avec succès !'
          : result['erreur'] ?? 'Erreur'),
      backgroundColor: result['success'] == true
          ? AppTheme.success : AppTheme.error,
    ));
  }
}

// ── Sheet ajuster capital ─────────────────────────────────────────────────────
class _AjusterCapitalSheet extends StatefulWidget {
  final StandModel stand;
  const _AjusterCapitalSheet({required this.stand});

  @override
  State<_AjusterCapitalSheet> createState() => _AjusterCapitalSheetState();
}

class _AjusterCapitalSheetState extends State<_AjusterCapitalSheet> {
  String _type = 'ajout_especes';
  String? _operateur;
  final _montantCtrl = TextEditingController();
  final _motifCtrl   = TextEditingController();
  bool _chargement   = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      {'code': 'ajout_especes',    'label': '+ Espèces',   'icon': Icons.add_circle_outline,    'color': AppTheme.success},
      {'code': 'retrait_especes',  'label': '- Espèces',   'icon': Icons.remove_circle_outline, 'color': AppTheme.error},
      {'code': 'ajout_sim',        'label': '+ SIM',       'icon': Icons.sim_card_outlined,     'color': Colors.blue},
      {'code': 'retrait_sim',      'label': '- SIM',       'icon': Icons.sim_card_outlined,     'color': Colors.orange},
    ];
    final needSim = _type == 'ajout_sim' || _type == 'retrait_sim';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 10,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Ajuster capital — ${widget.stand.nom}',
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: types.map((t) {
              final sel = _type == t['code'];
              final col = t['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() {
                  _type = t['code'] as String;
                  _operateur = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? col.withValues(alpha: 0.2) : AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? col : AppTheme.divider,
                        width: sel ? 2 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t['icon'] as IconData, color: col, size: 16),
                    const SizedBox(width: 6),
                    Text(t['label'] as String,
                        style: TextStyle(color: col,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              );
            }).toList(),
          ),
          if (needSim) ...[
            const SizedBox(height: 14),
            const Text('Opérateur',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: Operateur.values.map((op) {
                final sel = _operateur == op.code;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _operateur = op.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? Color(op.couleurHex).withValues(alpha: 0.2)
                              : AppTheme.backgroundDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? Color(op.couleurHex)
                                  : AppTheme.divider,
                              width: sel ? 2 : 1),
                        ),
                        child: Text(op.code, textAlign: TextAlign.center,
                            style: TextStyle(
                                color: sel
                                    ? Color(op.couleurHex)
                                    : Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0 FCFA',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true, fillColor: Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _motifCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Motif (obligatoire)',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true, fillColor: Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _chargement ? null : _appliquer,
              child: _chargement
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Appliquer',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Future<void> _appliquer() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) return;
    if (_motifCtrl.text.trim().isEmpty) return;
    final needSim = _type == 'ajout_sim' || _type == 'retrait_sim';
    if (needSim && _operateur == null) return;

    setState(() => _chargement = true);
    final p = context.read<AppProvider>();
    final result = await p.ajusterCapitalStand(
      standId: widget.stand.id,
      type: _type,
      montant: montant,
      motif: _motifCtrl.text.trim(),
      operateur: _operateur,
    );
    if (!mounted) return;
    setState(() => _chargement = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? 'Capital ajusté avec succès !'
          : result['erreur'] ?? 'Erreur'),
      backgroundColor: result['success'] == true
          ? AppTheme.success : AppTheme.error,
    ));
  }
}
