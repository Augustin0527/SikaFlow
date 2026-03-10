import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/plan_config_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN DE CONFIGURATION DES PLANS — Super Admin
// Permet de modifier les plans d'abonnement (prix, stands, labels, etc.)
// et la configuration globale (remise annuelle, durée essai…)
// ─────────────────────────────────────────────────────────────────────────────

class AdminPlansConfigScreen extends StatefulWidget {
  const AdminPlansConfigScreen({super.key});

  @override
  State<AdminPlansConfigScreen> createState() => _AdminPlansConfigScreenState();
}

class _AdminPlansConfigScreenState extends State<AdminPlansConfigScreen>
    with SingleTickerProviderStateMixin {
  // Palette
  static const _bg      = Color(0xFF0A1628);
  static const _surface = Color(0xFF111E35);
  static const _card    = Color(0xFF1A2640);
  static const _border  = Color(0xFF253553);
  static const _orange  = Color(0xFFFF6B35);
  static const _success = Color(0xFF00C896);
  static const _textP   = Color(0xFFF0F4F8);
  static const _textS   = Color(0xFF8A9BB0);

  late TabController _tabs;
  List<PlanConfig>          _plans   = [];
  ConfigAbonnementGlobal    _global  = const ConfigAbonnementGlobal();
  bool _chargement = true;
  bool _sauvegarde = false;
  final _fmt = NumberFormat('#,###', 'fr_FR');

  // Couleurs prédéfinies pour les plans
  static const List<int> _couleursDisponibles = [
    0xFF4CAF50, 0xFF2196F3, 0xFFFF6B35, 0xFF9C27B0,
    0xFFFFCC00, 0xFF00BCD4, 0xFFE91E63, 0xFFFF5722,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final plans  = await ConfigAbonnementService.chargerPlans();
    final global = await ConfigAbonnementService.chargerGlobal();
    if (mounted) {
      setState(() {
      _plans   = List.from(plans);
      _global  = global;
      _chargement = false;
    });
    }
  }

  Future<void> _sauvegarder() async {
    // Validation : vérifier qu'il n'y a pas de chevauchement de stands
    final actifs = _plans.where((p) => p.actif).toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    for (int i = 0; i < actifs.length - 1; i++) {
      final curr = actifs[i];
      final next = actifs[i + 1];
      if (curr.maxStands != -1 && curr.maxStands >= next.minStands) {
        _snack('⚠ Chevauchement détecté entre ${curr.label} et ${next.label}. '
            'Vérifiez les plages de stands.', Colors.orange);
        return;
      }
    }

    setState(() => _sauvegarde = true);
    try {
      await ConfigAbonnementService.sauvegarderPlans(_plans);
      await ConfigAbonnementService.sauvegarderGlobal(_global);
      if (mounted) {
        _snack('✅ Configuration sauvegardée avec succès !', _success);
      }
    } catch (e) {
      if (mounted) _snack('❌ Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _sauvegarde = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          duration: const Duration(seconds: 3)),
    );
  }

  // ── AJOUTER un nouveau plan ───────────────────────────────────────────────
  void _ajouterPlan() {
    final nouveau = PlanConfig(
      code:        'plan_${_plans.length + 1}',
      label:       'Nouveau plan',
      minStands:   1,
      maxStands:   -1,
      prixMensuel: 5000,
      description: 'Description du plan',
      couleurHex:  _couleursDisponibles[_plans.length % _couleursDisponibles.length],
      actif:       true,
      ordre:       _plans.length + 1,
    );
    setState(() => _plans.add(nouveau));
    Future.delayed(const Duration(milliseconds: 100), () {
      _ouvrirEditeurPlan(_plans.length - 1);
    });
  }

  // ── SUPPRIMER un plan ─────────────────────────────────────────────────────
  Future<void> _supprimerPlan(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce plan ?',
            style: TextStyle(color: _textP, fontWeight: FontWeight.bold)),
        content: Text(
          'Le plan "${_plans[index].label}" sera supprimé définitivement.',
          style: const TextStyle(color: _textS),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: _textS))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _plans.removeAt(index));
      // Renuméroter les ordres
      for (int i = 0; i < _plans.length; i++) {
        _plans[i] = _plans[i].copyWith(ordre: i + 1);
      }
    }
  }

  // ── RÉORDONNER via glisser-déposer ────────────────────────────────────────
  void _reordonner(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _plans.removeAt(oldIndex);
      _plans.insert(newIndex, item);
      for (int i = 0; i < _plans.length; i++) {
        _plans[i] = _plans[i].copyWith(ordre: i + 1);
      }
    });
  }

  // ── OUVRIR éditeur de plan (bottom sheet) ─────────────────────────────────
  void _ouvrirEditeurPlan(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanEditeurSheet(
        plan: _plans[index],
        couleursDisponibles: _couleursDisponibles,
        onSave: (updated) {
          setState(() => _plans[index] = updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textP),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration des plans',
                style: TextStyle(color: _textP, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Modalités d\'abonnement',
                style: TextStyle(color: _textS, fontSize: 11)),
          ],
        ),
        actions: [
          if (_sauvegarde)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _sauvegarder,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _orange,
          labelColor: _orange,
          unselectedLabelColor: _textS,
          tabs: const [
            Tab(icon: Icon(Icons.view_list_rounded, size: 18), text: 'Plans'),
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Paramètres'),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildOngletPlans(),
                _buildOngletParametres(),
              ],
            ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: _ajouterPlan,
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau plan'),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONGLET 1 — Liste des plans
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOngletPlans() {
    final remise = _global.remiseAnnuelle;

    return Column(
      children: [
        // Bandeau d'aide
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _orange.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.drag_indicator_rounded, color: _orange, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Glissez pour réordonner les plans. Appuyez sur un plan pour le modifier.',
                style: TextStyle(color: _textS, fontSize: 12),
              ),
            ),
          ]),
        ),

        // Liste réordonnable
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            itemCount: _plans.length,
            onReorder: _reordonner,
            itemBuilder: (ctx, i) {
              final plan = _plans[i];
              return _buildPlanItem(plan, i, remise, key: ValueKey(plan.code + i.toString()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanItem(PlanConfig plan, int index, double remise,
      {required Key key}) {
    final color = Color(plan.couleurHex);
    final prixAnnuel = plan.prixMensuelAvecRemise(remise);
    final economie   = plan.economieAnnuelle(remise);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.actif ? color.withValues(alpha: 0.4) : _border,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _ouvrirEditeurPlan(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Drag handle
              const Icon(Icons.drag_indicator_rounded, color: _textS, size: 22),
              const SizedBox(width: 10),

              // Couleur + icône
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: plan.actif ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_rounded,
                    color: plan.actif ? color : _textS, size: 22),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(plan.label,
                          style: TextStyle(
                            color: plan.actif ? _textP : _textS,
                            fontWeight: FontWeight.bold, fontSize: 15,
                          )),
                      const SizedBox(width: 6),
                      if (!plan.actif)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _textS.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Inactif',
                              style: TextStyle(color: _textS, fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      plan.maxStands == -1
                          ? '${plan.minStands}+ stands'
                          : plan.minStands == plan.maxStands
                              ? '${plan.minStands} stand'
                              : '${plan.minStands}–${plan.maxStands} stands',
                      style: TextStyle(
                        color: plan.actif ? color : _textS, fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(plan.description,
                        style: const TextStyle(color: _textS, fontSize: 11)),
                  ],
                ),
              ),

              // Prix
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt.format(plan.prixMensuel)} F',
                    style: TextStyle(
                      color: plan.actif ? color : _textS,
                      fontWeight: FontWeight.bold, fontSize: 14,
                    ),
                  ),
                  const Text('/mois', style: TextStyle(color: _textS, fontSize: 10)),
                  if (remise > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt.format(prixAnnuel)} F/mois*',
                      style: const TextStyle(color: _success, fontSize: 10),
                    ),
                    Text(
                      'Éco. ${_fmt.format(economie)} F/an',
                      style: const TextStyle(color: _success, fontSize: 9),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),

              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      plan.actif ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: plan.actif ? _success : _textS,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _plans[index] = plan.copyWith(actif: !plan.actif);
                    }),
                    tooltip: plan.actif ? 'Désactiver' : 'Activer',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    onPressed: () => _supprimerPlan(index),
                    tooltip: 'Supprimer',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONGLET 2 — Paramètres globaux
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOngletParametres() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Réduction annuelle'),
          const SizedBox(height: 12),
          _paramCard(
            icon: Icons.percent_rounded,
            color: _success,
            titre: 'Remise sur abonnement annuel',
            sousTitre: 'Appliquée automatiquement lors du choix de la période annuelle',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_global.remiseAnnuelle * 100).round()} %',
                      style: const TextStyle(
                          color: _success, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'soit ${_fmt.format((_global.remiseAnnuelle * 100).round())} % de réduction',
                      style: const TextStyle(color: _textS, fontSize: 12),
                    ),
                  ],
                ),
                Slider(
                  value: _global.remiseAnnuelle,
                  min: 0.0,
                  max: 0.50,
                  divisions: 10,
                  activeColor: _success,
                  inactiveColor: _border,
                  label: '${(_global.remiseAnnuelle * 100).round()}%',
                  onChanged: (v) => setState(() {
                    _global = _global.copyWith(remiseAnnuelle: v);
                  }),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0%', style: TextStyle(color: _textS, fontSize: 11)),
                    Text('50%', style: TextStyle(color: _textS, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Période d\'essai'),
          const SizedBox(height: 12),
          _paramCard(
            icon: Icons.timer_outlined,
            color: Colors.blue,
            titre: 'Durée de l\'essai gratuit',
            sousTitre: 'Nombre de jours accordés à chaque nouvelle inscription',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_global.dureeEssaiJours}',
                      style: const TextStyle(
                          color: Colors.blue, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('jours', style: TextStyle(color: _textS, fontSize: 16)),
                    const Spacer(),
                    Switch(
                      value: _global.essaiActif,
                      activeThumbColor: _orange,
                      onChanged: (v) => setState(() {
                        _global = _global.copyWith(essaiActif: v);
                      }),
                    ),
                    Text(
                      _global.essaiActif ? 'Actif' : 'Désactivé',
                      style: TextStyle(
                        color: _global.essaiActif ? _orange : _textS,
                        fontSize: 13, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _global.dureeEssaiJours.toDouble(),
                  min: 7,
                  max: 90,
                  divisions: 83,
                  activeColor: Colors.blue,
                  inactiveColor: _border,
                  label: '${_global.dureeEssaiJours} jours',
                  onChanged: _global.essaiActif
                      ? (v) => setState(() {
                            _global = _global.copyWith(dureeEssaiJours: v.round());
                          })
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('7 j', style: TextStyle(color: _textS, fontSize: 11)),
                    Text('90 j', style: TextStyle(color: _textS, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Message promotionnel'),
          const SizedBox(height: 12),
          _paramCard(
            icon: Icons.campaign_rounded,
            color: _orange,
            titre: 'Texte affiché sur la page d\'accueil',
            sousTitre: 'Laissez vide pour ne rien afficher',
            child: TextField(
              controller: TextEditingController(text: _global.messagePromo),
              style: const TextStyle(color: _textP, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Profitez de 20% de réduction en vous abonnant annuellement !',
                hintStyle: const TextStyle(color: _textS, fontSize: 12),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _orange),
                ),
              ),
              onChanged: (v) => _global = _global.copyWith(messagePromo: v),
            ),
          ),

          const SizedBox(height: 20),
          // Aperçu de la remise
          _sectionTitle('Aperçu de la tarification'),
          const SizedBox(height: 12),
          ..._plans.where((p) => p.actif).map((plan) => _previewCard(plan)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String titre) => Row(children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: _orange, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(titre, style: const TextStyle(
            color: _textP, fontSize: 15, fontWeight: FontWeight.bold)),
      ]);

  Widget _paramCard({
    required IconData icon,
    required Color color,
    required String titre,
    required String sousTitre,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(color: _textP,
                    fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sousTitre, style: const TextStyle(color: _textS, fontSize: 11)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _previewCard(PlanConfig plan) {
    final remise = _global.remiseAnnuelle;
    final prixAnnuel = plan.prixMensuelAvecRemise(remise);
    final economie   = plan.economieAnnuelle(remise);
    final color      = Color(plan.couleurHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(plan.label,
                style: const TextStyle(color: _textP, fontWeight: FontWeight.w600)),
          ),
          Text('${_fmt.format(plan.prixMensuel)} F/mois',
              style: const TextStyle(color: _textS, fontSize: 12)),
          const SizedBox(width: 10),
          if (remise > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_fmt.format(prixAnnuel)} F/mois (-${(remise * 100).round()}%)',
                style: const TextStyle(color: _success, fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          if (remise > 0) ...[
            const SizedBox(width: 8),
            Text('Éco. ${_fmt.format(economie)} F/an',
                style: const TextStyle(color: _success, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet — Éditeur d'un plan
// ─────────────────────────────────────────────────────────────────────────────
class _PlanEditeurSheet extends StatefulWidget {
  final PlanConfig plan;
  final List<int>  couleursDisponibles;
  final ValueChanged<PlanConfig> onSave;

  const _PlanEditeurSheet({
    required this.plan,
    required this.couleursDisponibles,
    required this.onSave,
  });

  @override
  State<_PlanEditeurSheet> createState() => _PlanEditeurSheetState();
}

class _PlanEditeurSheetState extends State<_PlanEditeurSheet> {
  static const _bg     = Color(0xFF0A1628);
  static const _card   = Color(0xFF1A2640);
  static const _border = Color(0xFF253553);
  static const _orange = Color(0xFFFF6B35);
  static const _textP  = Color(0xFFF0F4F8);
  static const _textS  = Color(0xFF8A9BB0);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _minStandsCtrl;
  late TextEditingController _maxStandsCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _codeCtrl;
  bool         _illimite   = false;
  bool         _populaire  = false;
  int          _couleurHex = 0xFF4CAF50;
  List<String> _features   = [];
  final _featCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _labelCtrl     = TextEditingController(text: p.label);
    _descCtrl      = TextEditingController(text: p.description);
    _minStandsCtrl = TextEditingController(text: p.minStands.toString());
    _maxStandsCtrl = TextEditingController(
        text: p.maxStands == -1 ? '' : p.maxStands.toString());
    _prixCtrl      = TextEditingController(text: p.prixMensuel.toString());
    _codeCtrl      = TextEditingController(text: p.code);
    _illimite      = p.maxStands == -1;
    _couleurHex    = p.couleurHex;
    _populaire     = p.populaire;
    _features      = List<String>.from(p.features);
  }

  @override
  void dispose() {
    _labelCtrl.dispose(); _descCtrl.dispose();
    _minStandsCtrl.dispose(); _maxStandsCtrl.dispose();
    _prixCtrl.dispose(); _codeCtrl.dispose();
    _featCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.plan.copyWith(
      code:        _codeCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      label:       _labelCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      minStands:   int.tryParse(_minStandsCtrl.text) ?? 1,
      maxStands:   _illimite ? -1 : (int.tryParse(_maxStandsCtrl.text) ?? -1),
      prixMensuel: int.tryParse(_prixCtrl.text) ?? 0,
      couleurHex:  _couleurHex,
      populaire:   _populaire,
      features:    _features,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Color(_couleurHex).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.storefront_rounded,
                        color: Color(_couleurHex), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Modifier le plan',
                      style: TextStyle(color: _textP, fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: _textS)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Code & Label
              Row(children: [
                Expanded(child: _field(_codeCtrl, 'Code',
                    hint: 'ex: pro', icon: Icons.code_rounded,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null)),
                const SizedBox(width: 12),
                Expanded(child: _field(_labelCtrl, 'Nom affiché',
                    hint: 'ex: Pro', icon: Icons.label_rounded,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null)),
              ]),
              const SizedBox(height: 14),

              // Description
              _field(_descCtrl, 'Description',
                  hint: 'ex: Pour les agences établies',
                  icon: Icons.description_rounded),
              const SizedBox(height: 14),

              // Plage de stands
              const Text('Plage de stands',
                  style: TextStyle(color: _textS, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _field(_minStandsCtrl, 'Min stands',
                      hint: '1', icon: Icons.remove_rounded,
                      numeric: true,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Min ≥ 1';
                        return null;
                      }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(_maxStandsCtrl, 'Max stands',
                          hint: 'vide = illimité',
                          icon: Icons.add_rounded,
                          numeric: true,
                          enabled: !_illimite,
                          validator: (v) {
                            if (_illimite) return null;
                            final n = int.tryParse(v ?? '');
                            final min = int.tryParse(_minStandsCtrl.text) ?? 0;
                            if (n == null || n < min) return 'Max ≥ Min';
                            return null;
                          }),
                    ],
                  ),
                ),
              ]),
              Row(children: [
                Switch(
                  value: _illimite,
                  activeThumbColor: _orange,
                  onChanged: (v) => setState(() {
                    _illimite = v;
                    if (v) _maxStandsCtrl.clear();
                  }),
                ),
                const Text('Stands illimités (11+ ou similaire)',
                    style: TextStyle(color: _textS, fontSize: 13)),
              ]),
              const SizedBox(height: 14),

              // Prix mensuel
              _field(_prixCtrl, 'Prix mensuel (FCFA)',
                  hint: '12000', icon: Icons.payments_rounded,
                  numeric: true,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Prix invalide';
                    return null;
                  }),
              const SizedBox(height: 20),

              // Couleur
              const Text('Couleur du plan',
                  style: TextStyle(color: _textS, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.couleursDisponibles.map((hex) {
                  final sel = _couleurHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _couleurHex = hex),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Color(hex),
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: sel
                            ? [BoxShadow(color: Color(hex).withValues(alpha: 0.5),
                                blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Badge populaire
              Row(children: [
                Switch(
                  value: _populaire,
                  activeThumbColor: _orange,
                  onChanged: (v) => setState(() => _populaire = v),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 18),
                const SizedBox(width: 6),
                const Text('Badge « Populaire »',
                    style: TextStyle(color: _textS, fontSize: 13)),
              ]),
              const SizedBox(height: 16),

              // Features (liste des avantages)
              Row(children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    color: _orange, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('Fonctionnalités incluses',
                    style: TextStyle(color: _textP,
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              // Liste existante
              if (_features.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Aucune fonctionnalité ajoutée',
                      style: TextStyle(color: _textS, fontSize: 12)),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (old, nw) {
                    setState(() {
                      if (nw > old) nw--;
                      final item = _features.removeAt(old);
                      _features.insert(nw, item);
                    });
                  },
                  children: _features.asMap().entries.map((e) {
                    return Container(
                      key: ValueKey('feat_${e.key}'),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator_rounded,
                              color: _textS, size: 18),
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded,
                              color: Color(_couleurHex), size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value,
                              style: const TextStyle(
                                  color: _textP, fontSize: 13))),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.red, size: 16),
                            onPressed: () => setState(() {
                              _features.removeAt(e.key);
                            }),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              // Champ ajout
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _featCtrl,
                    style: const TextStyle(color: _textP, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: Rapports avancés + exports',
                      hintStyle: const TextStyle(color: _textS, fontSize: 12),
                      prefixIcon: const Icon(Icons.add_task_rounded,
                          color: _orange, size: 18),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _orange, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onFieldSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setState(() {
                          _features.add(v.trim());
                          _featCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final v = _featCtrl.text.trim();
                    if (v.isNotEmpty) {
                      setState(() {
                        _features.add(v);
                        _featCtrl.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
              ]),
              const SizedBox(height: 24),

              // Bouton valider
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Valider les modifications',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    bool numeric = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      style: const TextStyle(color: _textP, fontSize: 14),
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _textS, fontSize: 12),
        hintStyle: const TextStyle(color: _textS, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, color: enabled ? _orange : _textS, size: 18)
            : null,
        filled: true,
        fillColor: enabled ? _bg : _border.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
