import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_config_model.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN D'ABONNEMENT — Gestionnaire
// Utilise les plans dynamiques définis par le super admin dans Firestore
// ─────────────────────────────────────────────────────────────────────────────

class AbonnementGestionnaireScreen extends StatefulWidget {
  final String entrepriseId;
  final Map<String, dynamic>? entrepriseData;
  const AbonnementGestionnaireScreen({
    super.key,
    required this.entrepriseId,
    this.entrepriseData,
  });

  @override
  State<AbonnementGestionnaireScreen> createState() =>
      _AbonnementGestionnaireScreenState();
}

class _AbonnementGestionnaireScreenState
    extends State<AbonnementGestionnaireScreen> {
  // ── Couleurs ────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF0A1628);
  static const _surface = Color(0xFF111E35);
  static const _card    = Color(0xFF1A2640);
  static const _border  = Color(0xFF253553);
  static const _orange  = Color(0xFFFF6B35);
  static const _success = Color(0xFF00C896);
  static const _textP   = Color(0xFFF0F4F8);
  static const _textS   = Color(0xFF8A9BB0);

  final _fs  = FirestoreService();
  final _fmt = NumberFormat('#,###', 'fr_FR');

  // ── State ────────────────────────────────────────────────────────────────────
  List<PlanConfig>       _plans    = [];
  ConfigAbonnementGlobal _cfg      = const ConfigAbonnementGlobal();
  bool _chargement      = true;
  bool _periodeAnnuelle = false;
  PlanConfig? _planSelectionne;
  String _modePaiement  = 'mtn'; // mtn | moov | carte
  bool _enTraitement    = false;

  // Infos abonnement actuel
  String? _statutActuel;
  DateTime? _dateExpiration;
  int _nbStandsActifs  = 0;

  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
    if (widget.entrepriseData != null) {
      _statutActuel   = widget.entrepriseData!['statut'] as String?;
      _dateExpiration = (widget.entrepriseData!['date_expiration_abonnement']
              as dynamic)
          ?.toDate() as DateTime?;
      _nbStandsActifs = (widget.entrepriseData!['nb_stands'] as int?) ?? 0;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final plans = await ConfigAbonnementService.chargerPlans();
      final cfg   = await ConfigAbonnementService.chargerGlobal();

      // Recharger les données entreprise pour avoir le nb_stands à jour
      final entData = await _fs.getEntreprise(widget.entrepriseId);
      if (mounted) {
        setState(() {
          _plans    = plans.where((p) => p.actif).toList();
          _cfg      = cfg;
          _chargement = false;
          if (entData != null) {
            _statutActuel   = entData['statut'] as String?;
            _dateExpiration = (entData['date_expiration_abonnement'] as dynamic)
                ?.toDate() as DateTime?;
            _nbStandsActifs = (entData['nb_stands'] as int?) ?? 0;
          }
          // Pré-sélectionner le plan recommandé
          if (_plans.isNotEmpty && _planSelectionne == null) {
            _planSelectionne = ConfigAbonnementService.planPourNombreDeStands(
                _plans, _nbStandsActifs > 0 ? _nbStandsActifs : 1);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // ── Calcul de prix ──────────────────────────────────────────────────────────
  int get _prixMensuelAffiche {
    if (_planSelectionne == null) return 0;
    return _periodeAnnuelle
        ? _planSelectionne!.prixMensuelAvecRemise(_cfg.remiseAnnuelle)
        : _planSelectionne!.prixMensuel;
  }

  int get _totalAPayer {
    if (_planSelectionne == null) return 0;
    return _periodeAnnuelle
        ? _planSelectionne!.totalPeriode(12, _cfg.remiseAnnuelle)
        : _planSelectionne!.prixMensuel;
  }

  int get _economie {
    if (_planSelectionne == null || !_periodeAnnuelle) return 0;
    return _planSelectionne!.economieAnnuelle(_cfg.remiseAnnuelle);
  }

  String get _labelPeriode => _periodeAnnuelle ? '12 mois (Annuel)' : '1 mois (Mensuel)';

  // ── Souscrire ────────────────────────────────────────────────────────────────
  Future<void> _souscrire() async {
    if (_planSelectionne == null) {
      _snack('Veuillez sélectionner un plan', Colors.orange);
      return;
    }

    // Confirmation
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmationDialog(
        plan:             _planSelectionne!,
        periodeAnnuelle:  _periodeAnnuelle,
        prixMensuel:      _prixMensuelAffiche,
        total:            _totalAPayer,
        economie:         _economie,
        modePaiement:     _modePaiement,
        fmt:              _fmt,
        remise:           _cfg.remiseAnnuelle,
      ),
    );
    if (ok != true) return;

    setState(() => _enTraitement = true);
    try {
      await _fs.activerAbonnement(
        entrepriseId:  widget.entrepriseId,
        type:          _periodeAnnuelle ? 'annuel' : 'mensuel',
        dureeMois:     _periodeAnnuelle ? 12 : 1,
        montant:       _totalAPayer.toDouble(),
        modePaiement:  _modePaiement,
        planCode:      _planSelectionne!.code,
      );
      if (mounted) {
        _snack('✅ Demande d\'abonnement enregistrée !', _success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snack('Erreur : $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _enTraitement = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textP),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abonnement SikaFlow',
                style: TextStyle(
                    color: _textP,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('Choisir un plan adapté à vos besoins',
                style: TextStyle(color: _textS, fontSize: 11)),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : RefreshIndicator(
              onRefresh: _charger,
              color: _orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Statut actuel ────────────────────────────────────────
                    _buildStatutActuel(),
                    const SizedBox(height: 20),

                    // ── Stands actifs ────────────────────────────────────────
                    if (_nbStandsActifs > 0) ...[
                      _buildInfoStands(),
                      const SizedBox(height: 20),
                    ],

                    // ── Toggle mensuel / annuel ──────────────────────────────
                    _buildTogglePeriode(),
                    const SizedBox(height: 24),

                    // ── Grille des plans ─────────────────────────────────────
                    const Text('Choisir un plan',
                        style: TextStyle(
                            color: _textP,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._plans.map((plan) => _buildPlanCard(plan)),
                    const SizedBox(height: 24),

                    // ── Récapitulatif ────────────────────────────────────────
                    if (_planSelectionne != null) ...[
                      _buildRecapitulatif(),
                      const SizedBox(height: 20),
                    ],

                    // ── Mode de paiement ─────────────────────────────────────
                    const Text('Mode de paiement',
                        style: TextStyle(
                            color: _textP,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildModePaiement(),
                    const SizedBox(height: 24),

                    // ── Infos contact (optionnel) ────────────────────────────
                    _buildInfoContact(),
                    const SizedBox(height: 32),

                    // ── Bouton souscrire ─────────────────────────────────────
                    _buildBoutonSouscrire(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '🔒 Paiement sécurisé • L\'admin activera votre abonnement après vérification',
                        style: TextStyle(color: _textS, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Statut actuel ────────────────────────────────────────────────────────────
  Widget _buildStatutActuel() {
    final estEssai   = _statutActuel == 'essai';
    final estActif   = _statutActuel == 'actif';
    final now        = DateTime.now();
    final estExpire  = _dateExpiration != null && _dateExpiration!.isBefore(now);
    final joursRestants = _dateExpiration != null
        ? _dateExpiration!.difference(now).inDays
        : 0;

    Color couleur;
    String titre;
    String sous;
    IconData icone;

    if (estEssai) {
      couleur = _orange;
      icone   = Icons.hourglass_top_rounded;
      titre   = 'Essai gratuit en cours';
      sous    = joursRestants > 0
          ? '$joursRestants jour${joursRestants > 1 ? "s" : ""} restant${joursRestants > 1 ? "s" : ""}'
          : 'Expiré';
    } else if (estActif && !estExpire) {
      couleur = _success;
      icone   = Icons.check_circle_rounded;
      titre   = 'Abonnement actif';
      sous    = 'Expire le ${DateFormat('dd/MM/yyyy').format(_dateExpiration!)}';
    } else {
      couleur = Colors.red;
      icone   = Icons.warning_rounded;
      titre   = 'Abonnement expiré';
      sous    = 'Renouvelez pour continuer à utiliser SikaFlow';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: couleur, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(sous,
                    style: const TextStyle(color: _textS, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info stands ──────────────────────────────────────────────────────────────
  Widget _buildInfoStands() {
    final planRecommande = _plans.isNotEmpty
        ? ConfigAbonnementService.planPourNombreDeStands(_plans, _nbStandsActifs)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: _orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_nbStandsActifs stand${_nbStandsActifs > 1 ? "s" : ""} actif${_nbStandsActifs > 1 ? "s" : ""}',
                  style: const TextStyle(
                      color: _textP,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                if (planRecommande != null)
                  Text(
                    'Plan recommandé : ${planRecommande.label}',
                    style: const TextStyle(color: _textS, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (planRecommande != null)
            GestureDetector(
              onTap: () => setState(() => _planSelectionne = planRecommande),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orange.withValues(alpha: 0.4)),
                ),
                child: const Text('Choisir',
                    style: TextStyle(
                        color: _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Toggle période ────────────────────────────────────────────────────────────
  Widget _buildTogglePeriode() {
    final pct = (_cfg.remiseAnnuelle * 100).round();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _periodeBtn('Mensuel', !_periodeAnnuelle, () {
            setState(() => _periodeAnnuelle = false);
          }),
          _periodeBtn(
            pct > 0 ? 'Annuel  −$pct%' : 'Annuel',
            _periodeAnnuelle,
            () => setState(() => _periodeAnnuelle = true),
          ),
        ],
      ),
    );
  }

  Widget _periodeBtn(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _textS,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Carte d'un plan ───────────────────────────────────────────────────────────
  Widget _buildPlanCard(PlanConfig plan) {
    final selected    = _planSelectionne?.code == plan.code;
    final color       = Color(plan.couleurHex);
    final prixM       = _periodeAnnuelle
        ? plan.prixMensuelAvecRemise(_cfg.remiseAnnuelle)
        : plan.prixMensuel;
    final totalAnnuel = plan.totalPeriode(12, _cfg.remiseAnnuelle);
    final economie    = plan.economieAnnuelle(_cfg.remiseAnnuelle);
    final estRecommande = _nbStandsActifs > 0 &&
        ConfigAbonnementService.planPourNombreDeStands(
                _plans, _nbStandsActifs)
            .code ==
            plan.code;

    return GestureDetector(
      onTap: () => setState(() => _planSelectionne = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : _border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Icône + sélection
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: selected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 26)
                  : Icon(Icons.storefront_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(plan.label,
                        style: TextStyle(
                          color: selected ? color : _textP,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                    if (estRecommande) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Recommandé',
                            style: TextStyle(
                                color: _orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(plan.description,
                      style: const TextStyle(color: _textS, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(plan.maxStandsLabel,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Prix
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _fmt.format(prixM),
                        style: TextStyle(
                          color: selected ? color : _textP,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(
                        text: ' F',
                        style: TextStyle(
                            color: _textS,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Text('/mois', style: TextStyle(color: _textS, fontSize: 10)),
                if (_periodeAnnuelle && _cfg.remiseAnnuelle > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt.format(totalAnnuel)} F/an',
                    style: const TextStyle(
                        color: _success, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Éco. ${_fmt.format(economie)} F',
                    style: const TextStyle(color: _success, fontSize: 10),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Récapitulatif ─────────────────────────────────────────────────────────────
  Widget _buildRecapitulatif() {
    if (_planSelectionne == null) return const SizedBox();
    final remise = (_cfg.remiseAnnuelle * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded, color: _orange, size: 20),
            const SizedBox(width: 8),
            const Text('Récapitulatif',
                style: TextStyle(
                    color: _textP,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          _ligneRecap('Plan', _planSelectionne!.label),
          _ligneRecap('Période', _labelPeriode),
          _ligneRecap('Prix unitaire', '${_fmt.format(_planSelectionne!.prixMensuel)} F/mois'),
          if (_periodeAnnuelle && _cfg.remiseAnnuelle > 0) ...[
            _ligneRecap('Remise annuelle', '-$remise%', couleur: _success),
            _ligneRecap(
              'Prix avec remise',
              '${_fmt.format(_prixMensuelAffiche)} F/mois',
              couleur: _success,
            ),
            _ligneRecap(
              'Économie réalisée',
              '${_fmt.format(_economie)} F',
              couleur: _success,
            ),
          ],
          const Divider(color: _border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL À PAYER',
                  style: TextStyle(
                      color: _textP,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(
                '${_fmt.format(_totalAPayer)} FCFA',
                style: const TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneRecap(String label, String valeur, {Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textS, fontSize: 13)),
          Text(valeur,
              style: TextStyle(
                  color: couleur ?? _textP,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Mode de paiement ──────────────────────────────────────────────────────────
  Widget _buildModePaiement() {
    return Row(
      children: [
        _paiementChip('mtn', 'MTN MoMo', const Color(0xFFFFCC00)),
        const SizedBox(width: 8),
        _paiementChip('moov', 'Moov Money', Colors.blue),
        const SizedBox(width: 8),
        _paiementChip('carte', 'Carte bancaire', Colors.green),
      ],
    );
  }

  Widget _paiementChip(String mode, String label, Color couleur) {
    final selected = _modePaiement == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modePaiement = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? couleur.withValues(alpha: 0.12) : _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? couleur : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? couleur : _textS,
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Info contact ──────────────────────────────────────────────────────────────
  Widget _buildInfoContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact pour le paiement',
            style: TextStyle(
                color: _textP, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Ces informations seront transmises à l\'administrateur pour valider votre abonnement.',
          style: TextStyle(color: _textS, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _champTexte(_nomCtrl, 'Nom complet (optionnel)', Icons.person_rounded),
        const SizedBox(height: 10),
        _champTexte(
          _telCtrl,
          'Numéro de téléphone (optionnel)',
          Icons.phone_rounded,
          type: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _champTexte(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: _textP, fontSize: 14),
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textS, fontSize: 13),
        prefixIcon: Icon(icon, color: _textS, size: 20),
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
            borderSide: const BorderSide(color: _orange, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }

  // ── Bouton souscrire ──────────────────────────────────────────────────────────
  Widget _buildBoutonSouscrire() {
    final peutSouscrire = _planSelectionne != null && !_enTraitement;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: peutSouscrire ? _orange : _border,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: peutSouscrire ? _souscrire : null,
        child: _enTraitement
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                _planSelectionne == null
                    ? 'Sélectionnez un plan'
                    : 'Demander l\'abonnement — ${_fmt.format(_totalAPayer)} FCFA',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog de confirmation
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmationDialog extends StatelessWidget {
  final PlanConfig plan;
  final bool periodeAnnuelle;
  final int prixMensuel;
  final int total;
  final int economie;
  final String modePaiement;
  final NumberFormat fmt;
  final double remise;

  const _ConfirmationDialog({
    required this.plan,
    required this.periodeAnnuelle,
    required this.prixMensuel,
    required this.total,
    required this.economie,
    required this.modePaiement,
    required this.fmt,
    required this.remise,
  });

  static const _bg     = Color(0xFF1A2640);
  static const _border = Color(0xFF253553);
  static const _orange = Color(0xFFFF6B35);
  static const _success= Color(0xFF00C896);
  static const _textP  = Color(0xFFF0F4F8);
  static const _textS  = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    final pct = (remise * 100).round();
    final color = Color(plan.couleurHex);

    return AlertDialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.storefront_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Confirmer l\'abonnement',
              style: TextStyle(
                  color: _textP,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          _ligne('Plan', plan.label, color),
          _ligne('Période', periodeAnnuelle ? '12 mois (annuel)' : '1 mois (mensuel)'),
          _ligne('Prix unitaire', '${fmt.format(plan.prixMensuel)} F/mois'),
          if (periodeAnnuelle && pct > 0) ...[
            _ligne('Remise annuelle', '-$pct%', _success),
            _ligne('Prix avec remise', '${fmt.format(prixMensuel)} F/mois', _success),
            _ligne('Économie', '${fmt.format(economie)} F', _success),
          ],
          const Divider(color: _border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      color: _textP,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('${fmt.format(total)} FCFA',
                  style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Après validation, l\'administrateur activera votre abonnement sous 24h.',
              style: TextStyle(color: _textS, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(color: _textS)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmer',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _ligne(String label, String valeur, [Color? couleur]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textS, fontSize: 13)),
          Text(valeur,
              style: TextStyle(
                  color: couleur ?? _textP,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
