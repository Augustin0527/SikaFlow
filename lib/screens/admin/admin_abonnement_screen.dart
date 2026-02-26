import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/plan_config_model.dart';
import '../../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN ADMIN — Attribution manuelle d'abonnement
// Utilise les plans dynamiques Firestore
// ─────────────────────────────────────────────────────────────────────────────

class AdminAbonnementScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> entreprises;
  const AdminAbonnementScreen({super.key, required this.entreprises});

  @override
  State<AdminAbonnementScreen> createState() => _AdminAbonnementScreenState();
}

class _AdminAbonnementScreenState extends State<AdminAbonnementScreen> {
  static const _bg     = Color(0xFF0A1628);
  static const _card   = Color(0xFF1A2640);
  static const _border = Color(0xFF253553);
  static const _orange = Color(0xFFFF6B35);
  static const _success= Color(0xFF00C896);
  static const _textP  = Color(0xFFF0F4F8);
  static const _textS  = Color(0xFF8A9BB0);

  final _fs  = FirestoreService();
  final _fmt = NumberFormat('#,###', 'fr_FR');
  final _notesCtrl = TextEditingController();

  // State
  String? _entrepriseSelectionnee;
  List<PlanConfig>       _plans   = [];
  ConfigAbonnementGlobal _cfg     = const ConfigAbonnementGlobal();
  PlanConfig?            _planSelectionne;
  bool _periodeAnnuelle = false;
  bool _chargement      = true;
  bool _enTraitement    = false;
  double _montantPersonnalise = 0;
  bool _montantPersonnaliseActif = false;

  @override
  void initState() {
    super.initState();
    _chargerPlans();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerPlans() async {
    final plans = await ConfigAbonnementService.chargerPlans();
    final cfg   = await ConfigAbonnementService.chargerGlobal();
    if (mounted) setState(() {
      _plans   = plans.where((p) => p.actif).toList();
      _cfg     = cfg;
      _chargement = false;
      if (_plans.isNotEmpty) _planSelectionne = _plans.first;
    });
  }

  int get _prixCalcule {
    if (_planSelectionne == null) return 0;
    return _periodeAnnuelle
        ? _planSelectionne!.totalPeriode(12, _cfg.remiseAnnuelle)
        : _planSelectionne!.prixMensuel;
  }

  int get _dureeMois => _periodeAnnuelle ? 12 : 1;

  double get _montantFinal =>
      _montantPersonnaliseActif ? _montantPersonnalise : _prixCalcule.toDouble();

  Future<void> _accorderAbonnement() async {
    if (_entrepriseSelectionnee == null) {
      _snack('Sélectionnez une entreprise', Colors.orange);
      return;
    }
    if (_planSelectionne == null) {
      _snack('Sélectionnez un plan', Colors.orange);
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer l\'abonnement',
            style: TextStyle(color: _textP, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ligneDialog('Entreprise', _nomEntreprise(_entrepriseSelectionnee!)),
            _ligneDialog('Plan', _planSelectionne!.label),
            _ligneDialog('Durée', '$_dureeMois mois'),
            _ligneDialog('Montant', '${_fmt.format(_montantFinal)} FCFA'),
            _ligneDialog('Mode', 'Manuel (Admin)'),
            if (_notesCtrl.text.trim().isNotEmpty)
              _ligneDialog('Note', _notesCtrl.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: _textS)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      setState(() => _enTraitement = true);
      try {
        await _fs.activerAbonnement(
          entrepriseId: _entrepriseSelectionnee!,
          type:         _periodeAnnuelle ? 'annuel' : 'mensuel',
          dureeMois:    _dureeMois,
          montant:      _montantFinal,
          modePaiement: 'manuel',
          adminId:      'super_admin',
          planCode:     _planSelectionne!.code,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Abonnement accordé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _snack('Erreur : $e', Colors.red);
      } finally {
        if (mounted) setState(() => _enTraitement = false);
      }
    }
  }

  String _nomEntreprise(String id) {
    final e = widget.entreprises.where((e) => e.id == id).firstOrNull;
    if (e == null) return id;
    final data = e.data() as Map<String, dynamic>;
    return data['nom'] ?? id;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Widget _ligneDialog(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textS, fontSize: 13)),
        Flexible(
          child: Text(valeur,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: _textP, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111E35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textP),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abonnement Manuel',
                style: TextStyle(
                    color: _textP,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('Attribution par l\'administrateur',
                style: TextStyle(color: _textS, fontSize: 11)),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _enTraitement
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _orange),
                      SizedBox(height: 16),
                      Text('Activation en cours...',
                          style: TextStyle(color: _textS)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _success.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _success.withValues(alpha: 0.25)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: _success, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Attribution manuelle. Le paiement a été reçu hors-ligne (Mobile Money, espèces…). Le plan sera activé immédiatement.',
                              style: TextStyle(color: _textS, fontSize: 12),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Sélection entreprise
                      _sectionLabel('Entreprise *'),
                      const SizedBox(height: 8),
                      _buildEntrepriseDropdown(),
                      const SizedBox(height: 20),

                      // Sélection plan
                      _sectionLabel('Plan d\'abonnement *'),
                      const SizedBox(height: 8),
                      ..._plans.map((p) => _buildPlanTile(p)),
                      const SizedBox(height: 20),

                      // Période
                      _sectionLabel('Période'),
                      const SizedBox(height: 8),
                      _buildPeriodeSelector(),
                      const SizedBox(height: 20),

                      // Récapitulatif prix
                      if (_planSelectionne != null) ...[
                        _buildPrixCard(),
                        const SizedBox(height: 20),
                      ],

                      // Montant personnalisé
                      _buildMontantPersonnalise(),
                      const SizedBox(height: 20),

                      // Notes
                      _sectionLabel('Notes / Référence paiement'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesCtrl,
                        style: const TextStyle(color: _textP, fontSize: 14),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'ex: Paiement reçu via MTN le 12/01/2025…',
                          hintStyle:
                              const TextStyle(color: _textS, fontSize: 12),
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _orange, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Colors.white),
                          label: const Text(
                            'Accorder l\'abonnement',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: _accorderAbonnement,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          color: _textP, fontSize: 14, fontWeight: FontWeight.bold));

  Widget _buildEntrepriseDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _entrepriseSelectionnee,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('Sélectionner une entreprise',
                style: TextStyle(color: _textS, fontSize: 14)),
          ),
          dropdownColor: _card,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          icon: const Icon(Icons.expand_more_rounded, color: _textS),
          items: widget.entreprises.map((e) {
            final data = e.data() as Map<String, dynamic>;
            final statut = data['statut'] ?? 'essai';
            return DropdownMenuItem<String>(
              value: e.id,
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _orange.withValues(alpha: 0.15),
                  child: Text(
                    ((data['nom'] ?? '?') as String)[0].toUpperCase(),
                    style: const TextStyle(
                        color: _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data['nom'] ?? e.id,
                          style: const TextStyle(color: _textP, fontSize: 13)),
                      Text(statut,
                          style: const TextStyle(color: _textS, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            );
          }).toList(),
          onChanged: (v) => setState(() => _entrepriseSelectionnee = v),
        ),
      ),
    );
  }

  Widget _buildPlanTile(PlanConfig plan) {
    final selected = _planSelectionne?.code == plan.code;
    final color    = Color(plan.couleurHex);
    final prixM    = _periodeAnnuelle
        ? plan.prixMensuelAvecRemise(_cfg.remiseAnnuelle)
        : plan.prixMensuel;
    final total = _periodeAnnuelle
        ? plan.totalPeriode(12, _cfg.remiseAnnuelle)
        : plan.prixMensuel;

    return GestureDetector(
      onTap: () => setState(() => _planSelectionne = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : _border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: selected
                ? Icon(Icons.check_rounded, color: color, size: 22)
                : Icon(Icons.storefront_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.label,
                  style: TextStyle(
                      color: selected ? color : _textP,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(plan.maxStandsLabel,
                  style: TextStyle(color: color, fontSize: 12)),
              Text(plan.description,
                  style: const TextStyle(color: _textS, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_fmt.format(prixM)} F/mois',
                style: TextStyle(
                    color: selected ? color : _textP,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(
              'Total : ${_fmt.format(total)} F',
              style: const TextStyle(color: _textS, fontSize: 11),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPeriodeSelector() {
    final pct = (_cfg.remiseAnnuelle * 100).round();
    return Row(children: [
      _periodeChip(false, 'Mensuel', '1 mois', Colors.blue),
      const SizedBox(width: 10),
      _periodeChip(
        true,
        pct > 0 ? 'Annuel −$pct%' : 'Annuel',
        '12 mois',
        _success,
      ),
    ]);
  }

  Widget _periodeChip(
      bool annuel, String label, String sousTitre, Color couleur) {
    final selected = _periodeAnnuelle == annuel;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _periodeAnnuelle = annuel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? couleur.withValues(alpha: 0.1) : _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? couleur : _border,
                width: selected ? 1.5 : 1),
          ),
          child: Column(children: [
            if (selected)
              Icon(Icons.check_circle_rounded, color: couleur, size: 18),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? couleur : _textP,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(sousTitre,
                style: const TextStyle(color: _textS, fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPrixCard() {
    if (_planSelectionne == null) return const SizedBox();
    final color   = Color(_planSelectionne!.couleurHex);
    final prixM   = _periodeAnnuelle
        ? _planSelectionne!.prixMensuelAvecRemise(_cfg.remiseAnnuelle)
        : _planSelectionne!.prixMensuel;
    final total   = _periodeAnnuelle
        ? _planSelectionne!.totalPeriode(12, _cfg.remiseAnnuelle)
        : _planSelectionne!.prixMensuel;
    final economie= _periodeAnnuelle
        ? _planSelectionne!.economieAnnuelle(_cfg.remiseAnnuelle)
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Plan ${_planSelectionne!.label}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text(
            _periodeAnnuelle ? 'Annuel' : 'Mensuel',
            style: const TextStyle(
                color: _textS, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
        const Divider(color: _border, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Prix / mois', style: TextStyle(color: _textS, fontSize: 13)),
          Text('${_fmt.format(prixM)} F',
              style: const TextStyle(color: _textP, fontWeight: FontWeight.w600)),
        ]),
        if (_periodeAnnuelle && economie > 0) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Économie', style: TextStyle(color: _textS, fontSize: 13)),
            Text('${_fmt.format(economie)} F',
                style: const TextStyle(
                    color: _success, fontWeight: FontWeight.w600)),
          ]),
        ],
        const Divider(color: _border, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('TOTAL À PAYER',
              style: TextStyle(
                  color: _textP,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text('${_fmt.format(total)} FCFA',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ]),
      ]),
    );
  }

  Widget _buildMontantPersonnalise() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Switch(
            value: _montantPersonnaliseActif,
            activeTrackColor: _orange,
            onChanged: (v) => setState(() {
              _montantPersonnaliseActif = v;
              if (v) _montantPersonnalise = _prixCalcule.toDouble();
            }),
          ),
          const SizedBox(width: 6),
          const Text('Montant personnalisé',
              style: TextStyle(color: _textP, fontSize: 14)),
        ]),
        if (_montantPersonnaliseActif) ...[
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(
                text: _montantPersonnalise.toStringAsFixed(0)),
            style: const TextStyle(color: _textP, fontSize: 14),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                _montantPersonnalise = double.tryParse(v) ?? _montantPersonnalise,
            decoration: InputDecoration(
              hintText: 'Montant en FCFA',
              hintStyle: const TextStyle(color: _textS),
              suffixText: 'FCFA',
              suffixStyle: const TextStyle(color: _textS),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _orange, width: 1.5)),
            ),
          ),
        ],
      ],
    );
  }
}
