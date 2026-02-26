import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/stand_model.dart';
import '../../models/operation_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';

class DemandeReequilibrageScreen extends StatefulWidget {
  final StandModel stand;
  const DemandeReequilibrageScreen({super.key, required this.stand});

  @override
  State<DemandeReequilibrageScreen> createState() =>
      _DemandeReequilibrageScreenState();
}

class _DemandeReequilibrageScreenState
    extends State<DemandeReequilibrageScreen> {
  String _type = 'especes_vers_sim';
  String? _opSource;
  String? _opDest;
  final _montantCtrl = TextEditingController();
  final _motifCtrl   = TextEditingController();
  bool _chargement   = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _types = [
    {
      'code': 'especes_vers_sim',
      'label': 'Espèces → SIM',
      'icon': Icons.arrow_forward,
      'desc': 'Convertir des espèces en solde SIM (trop d\'espèces)',
    },
    {
      'code': 'sim_vers_especes',
      'label': 'SIM → Espèces',
      'icon': Icons.arrow_back,
      'desc': 'Convertir un solde SIM en espèces (trop de solde SIM)',
    },
    {
      'code': 'sim_vers_sim',
      'label': 'SIM → SIM',
      'icon': Icons.swap_horiz,
      'desc': 'Transférer entre deux opérateurs',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sims = widget.stand.sims.where((s) => s.actif).toList();
    final operateurs = sims.map((s) => s.operateur).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Demande de rééquilibrage',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Le gestionnaire sera notifié et devra approuver cette demande avant que les soldes ne soient modifiés.',
                  style: TextStyle(color: Colors.blue, fontSize: 12, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Type de rééquilibrage
          const Text('Type de rééquilibrage',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ..._types.map((t) => GestureDetector(
            onTap: () => setState(() {
              _type = t['code'] as String;
              _opSource = null;
              _opDest = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _type == t['code']
                    ? AppTheme.accentOrange.withValues(alpha: 0.1)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == t['code']
                      ? AppTheme.accentOrange
                      : AppTheme.divider,
                  width: _type == t['code'] ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Icon(t['icon'] as IconData,
                    color: _type == t['code']
                        ? AppTheme.accentOrange
                        : AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t['label'] as String,
                        style: TextStyle(
                            color: _type == t['code']
                                ? AppTheme.accentOrange
                                : Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text(t['desc'] as String,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
                if (_type == t['code'])
                  const Icon(Icons.check_circle,
                      color: AppTheme.accentOrange, size: 18),
              ]),
            ),
          )),

          const SizedBox(height: 16),

          // Opérateur(s)
          if (_type == 'sim_vers_sim') ...[
            _buildOperateurPicker(
              label: 'Opérateur source',
              operateurs: operateurs,
              valeur: _opSource,
              onChanged: (v) => setState(() => _opSource = v),
            ),
            const SizedBox(height: 12),
            _buildOperateurPicker(
              label: 'Opérateur destination',
              operateurs: operateurs.where((o) => o != _opSource).toList(),
              valeur: _opDest,
              onChanged: (v) => setState(() => _opDest = v),
            ),
          ] else if (_type == 'especes_vers_sim') ...[
            _buildOperateurPicker(
              label: 'Opérateur SIM à recharger',
              operateurs: operateurs,
              valeur: _opDest,
              onChanged: (v) => setState(() => _opDest = v),
            ),
          ] else if (_type == 'sim_vers_especes') ...[
            _buildOperateurPicker(
              label: 'Opérateur SIM à débiter',
              operateurs: operateurs,
              valeur: _opSource,
              onChanged: (v) => setState(() => _opSource = v),
            ),
          ],

          const SizedBox(height: 16),

          // Montant
          const Text('Montant',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                suffixText: 'FCFA',
                suffixStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Motif
          const Text('Motif de la demande',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _motifCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Expliquez pourquoi vous avez besoin de ce rééquilibrage...',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: const Text('Envoyer la demande',
                  style: TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _chargement ? null : _envoyer,
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildOperateurPicker({
    required String label,
    required List<String> operateurs,
    required String? valeur,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(
        children: operateurs.map((op) {
          final opEnum = Operateur.fromCode(op);
          final selected = valeur == op;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onChanged(op),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Color(opEnum.couleurHex).withValues(alpha: 0.2)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Color(opEnum.couleurHex)
                          : AppTheme.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(op,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: selected
                              ? Color(opEnum.couleurHex)
                              : Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Future<void> _envoyer() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) {
      _showSnack('Montant invalide');
      return;
    }
    if (_motifCtrl.text.trim().isEmpty) {
      _showSnack('Le motif est obligatoire');
      return;
    }
    if (_type == 'sim_vers_sim' && (_opSource == null || _opDest == null)) {
      _showSnack('Sélectionnez les deux opérateurs');
      return;
    }
    if (_type == 'especes_vers_sim' && _opDest == null) {
      _showSnack('Sélectionnez l\'opérateur SIM');
      return;
    }
    if (_type == 'sim_vers_especes' && _opSource == null) {
      _showSnack('Sélectionnez l\'opérateur SIM');
      return;
    }

    setState(() => _chargement = true);
    final p = context.read<AppProvider>();

    final result = await p.creerDemandeReequilibrage(
      standId: widget.stand.id,
      type: _type,
      montant: montant,
      motif: _motifCtrl.text.trim(),
      operateurSource: _opSource,
      operateurDestination: _opDest,
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: const Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 10),
            Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 50),
            SizedBox(height: 16),
            Text('Demande envoyée !',
                style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Votre gestionnaire sera notifié et traitera la demande rapidement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ]),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _showSnack(result['erreur'] ?? 'Erreur lors de l\'envoi');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
