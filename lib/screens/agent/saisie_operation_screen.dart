import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/stand_model.dart';
import '../../models/operation_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';

class SaisieOperationScreen extends StatefulWidget {
  final StandModel stand;
  const SaisieOperationScreen({super.key, required this.stand});

  @override
  State<SaisieOperationScreen> createState() => _SaisieOperationScreenState();
}

class _SaisieOperationScreenState extends State<SaisieOperationScreen> {
  String? _operateur;
  String? _typeOp;
  final _montantCtrl = TextEditingController();
  final _numClientCtrl = TextEditingController();
  final _nomClientCtrl = TextEditingController();
  bool _chargement = false;
  final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  void dispose() {
    _montantCtrl.dispose();
    _numClientCtrl.dispose();
    _nomClientCtrl.dispose();
    super.dispose();
  }

  String _fmt2(double v) => '${_fmt.format(v)} FCFA';

  @override
  Widget build(BuildContext context) {
    final sims = widget.stand.sims.where((s) => s.actif).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle opération',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(widget.stand.nom,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Étape 1 : Opérateur ─────────────────────────────────────────
          _buildEtapeLabel('1', 'Choisir l\'opérateur SIM'),
          const SizedBox(height: 10),
          Row(
            children: sims.map((sim) {
              final op = sim.operateurEnum;
              final selected = _operateur == op.code;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _operateur = op.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(op.couleurHex).withValues(alpha: 0.2)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? Color(op.couleurHex)
                              : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Text(op.code,
                            style: TextStyle(
                                color: selected
                                    ? Color(op.couleurHex)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(_fmt2(sim.solde),
                            style: TextStyle(
                                color: selected
                                    ? Color(op.couleurHex)
                                    : AppTheme.textSecondary,
                                fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Étape 2 : Type d'opération ──────────────────────────────────
          _buildEtapeLabel('2', 'Type d\'opération'),
          const SizedBox(height: 10),
          Row(
            children: TypeOperation.values.map((type) {
              final selected = _typeOp == type.code;
              final couleur = _couleurType(type);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _typeOp = type.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? couleur.withValues(alpha: 0.15)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? couleur : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Text(type.emoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(type.label,
                            style: TextStyle(
                                color: selected ? couleur : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Étape 3 : Montant ───────────────────────────────────────────
          _buildEtapeLabel('3', 'Montant'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                suffixText: 'FCFA',
                suffixStyle: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          // Montants rapides
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [500, 1000, 2000, 5000, 10000, 25000, 50000, 100000]
                .map((m) => GestureDetector(
                      onTap: () => setState(
                          () => _montantCtrl.text = m.toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Text('${_fmt.format(m)}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // ── Étape 4 : Client (optionnel) ────────────────────────────────
          _buildEtapeLabel('4', 'Client (optionnel)'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _buildInput(
                  ctrl: _numClientCtrl,
                  hint: 'Numéro client',
                  icon: Icons.phone_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInput(
                  ctrl: _nomClientCtrl,
                  hint: 'Nom client',
                  icon: Icons.person_outline),
            ),
          ]),

          const SizedBox(height: 32),

          // ── Bouton enregistrer ──────────────────────────────────────────
          _buildBoutonEnregistrer(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildEtapeLabel(String num, String label) {
    return Row(children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
            color: AppTheme.accentOrange, shape: BoxShape.circle),
        child: Center(
          child: Text(num,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBoutonEnregistrer() {
    final pret = _operateur != null &&
        _typeOp != null &&
        _montantCtrl.text.isNotEmpty &&
        double.tryParse(_montantCtrl.text) != null &&
        double.parse(_montantCtrl.text) > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (pret && !_chargement) ? _enregistrer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOrange,
          disabledBackgroundColor: AppTheme.divider,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _chargement
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('✅  ENREGISTRER L\'OPÉRATION',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _enregistrer() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) return;

    setState(() => _chargement = true);
    final p = context.read<AppProvider>();

    final result = await p.saisirOperation(
      standId: widget.stand.id,
      operateur: _operateur!,
      typeOperation: _typeOp!,
      montant: montant,
      numeroClient: _numClientCtrl.text.trim().isEmpty
          ? null
          : _numClientCtrl.text.trim(),
      nomClient: _nomClientCtrl.text.trim().isEmpty
          ? null
          : _nomClientCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (result['success'] == true) {
      _showSucces(montant, result['ristourne'] ?? 0.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['erreur'] ?? 'Erreur'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSucces(double montant, double ristourne) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              color: Color(0x1A4CAF50), shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Opération enregistrée !',
              style: TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_fmt2(montant),
              style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 22, fontWeight: FontWeight.bold)),
          if (ristourne > 0) ...[
            const SizedBox(height: 6),
            Text('Ristourne : +${_fmt2(ristourne)}',
                style: const TextStyle(color: Colors.amber, fontSize: 13)),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ferme dialog
              // Réinitialiser le formulaire pour une nouvelle saisie
              setState(() {
                _operateur = null;
                _typeOp = null;
                _montantCtrl.clear();
                _numClientCtrl.clear();
                _nomClientCtrl.clear();
              });
            },
            child: const Text('Nouvelle opération',
                style: TextStyle(color: AppTheme.accentOrange)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Terminer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _couleurType(TypeOperation type) {
    switch (type) {
      case TypeOperation.depot:       return AppTheme.success;
      case TypeOperation.retrait:     return AppTheme.error;
      case TypeOperation.creditForfait: return Colors.blue;
    }
    return Colors.white;
  }
}
