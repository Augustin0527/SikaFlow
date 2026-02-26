import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late TextEditingController _seuilEspAlerte;
  late TextEditingController _seuilEspCrit;
  late TextEditingController _seuilSimAlerte;
  late TextEditingController _seuilSimCrit;
  late TextEditingController _delaiModif;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    final ent = p.entrepriseActive;
    _seuilEspAlerte = TextEditingController(
        text: '${(ent?.seuilAlerteEspeces ?? 50000).toInt()}');
    _seuilEspCrit   = TextEditingController(
        text: '${(ent?.seuilCritiqueEspeces ?? 20000).toInt()}');
    _seuilSimAlerte = TextEditingController(
        text: '${(ent?.seuilAlerteSim ?? 30000).toInt()}');
    _seuilSimCrit   = TextEditingController(
        text: '${(ent?.seuilCritiqueSim ?? 10000).toInt()}');
    _delaiModif     = TextEditingController(
        text: '${ent?.delaiModificationHeures ?? 30}');
  }

  @override
  void dispose() {
    _seuilEspAlerte.dispose();
    _seuilEspCrit.dispose();
    _seuilSimAlerte.dispose();
    _seuilSimCrit.dispose();
    _delaiModif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final ent = p.entrepriseActive;

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configuration',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Seuils d'alerte
              _buildSection('Seuils d\'alerte', Icons.warning_amber_rounded,
                  const Color(0xFFFFB300), [
                _buildField('Alerte espèces (FCFA)',
                    _seuilEspAlerte, 'ex: 50000'),
                const SizedBox(height: 12),
                _buildField('Critique espèces (FCFA)',
                    _seuilEspCrit, 'ex: 20000'),
                const SizedBox(height: 12),
                _buildField('Alerte SIM (FCFA)',
                    _seuilSimAlerte, 'ex: 30000'),
                const SizedBox(height: 12),
                _buildField('Critique SIM (FCFA)',
                    _seuilSimCrit, 'ex: 10000'),
              ]),
              const SizedBox(height: 20),

              // Délai de modification
              _buildSection('Délai de modification', Icons.timer_outlined,
                  _orange, [
                _buildField('Délai (heures)',
                    _delaiModif, 'ex: 30',
                    hint2: 'Délai maximum après lequel les agents ne peuvent plus modifier'),
              ]),
              const SizedBox(height: 20),

              // Mode de saisie
              _buildSection('Mode de saisie', Icons.edit_note_rounded,
                  _success, [
                _buildSwitchRow(
                  'Mode détaillé',
                  'Chaque transaction est enregistrée individuellement',
                  ent?.modeSaisie == 'detail',
                  (v) => _updateModeSaisie(p, v ? 'detail' : 'synthese'),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  'Mode synthèse',
                  'Saisie de totaux journaliers par opérateur',
                  ent?.modeSaisie == 'synthese',
                  (v) => _updateModeSaisie(p, v ? 'synthese' : 'detail'),
                ),
              ]),
              const SizedBox(height: 20),

              // Visibilité des stands
              _buildSection('Visibilité stands pour les agents',
                  Icons.visibility_outlined, const Color(0xFF8B5CF6), [
                _buildSwitchRow(
                  'Vue fermée',
                  'L\'agent voit uniquement son stand',
                  ent?.visibiliteStands == 'ferme',
                  (v) => _updateVisibilite(p, 'ferme'),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  'Vue partielle',
                  'L\'agent voit les stats (sans montants) des autres stands',
                  ent?.visibiliteStands == 'partiel',
                  (v) => _updateVisibilite(p, 'partiel'),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  'Vue ouverte',
                  'L\'agent voit tous les stands avec les montants',
                  ent?.visibiliteStands == 'ouvert',
                  (v) => _updateVisibilite(p, 'ouvert'),
                ),
              ]),
              const SizedBox(height: 24),

              // Bouton enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Enregistrer la configuration',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _sauvegarder(ctx, p),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSection(String titre, IconData icon, Color color,
      List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(titre,
              style: const TextStyle(
                  color: _textPrim,
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {String? hint2}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: _textSec, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: _textPrim),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF607D8B)),
          helperText: hint2,
          helperStyle: const TextStyle(color: _textSec, fontSize: 10),
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _orange, width: 2)),
        ),
      ),
    ]);
  }

  Widget _buildSwitchRow(String label, String sub, bool val,
      ValueChanged<bool> onChanged) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: _textPrim, fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(sub,
              style: const TextStyle(color: _textSec, fontSize: 11)),
        ]),
      ),
      Switch(
        value: val,
        onChanged: onChanged,
        activeColor: _orange,
      ),
    ]);
  }

  void _updateModeSaisie(AppProvider p, String mode) {
    p.mettreAJourConfigEntreprise({'mode_saisie': mode});
  }

  void _updateVisibilite(AppProvider p, String visib) {
    p.mettreAJourConfigEntreprise({'visibilite_stands': visib});
  }

  Future<void> _sauvegarder(BuildContext ctx, AppProvider p) async {
    final data = <String, dynamic>{};

    final seuilEspA = double.tryParse(_seuilEspAlerte.text);
    final seuilEspC = double.tryParse(_seuilEspCrit.text);
    final seuilSimA = double.tryParse(_seuilSimAlerte.text);
    final seuilSimC = double.tryParse(_seuilSimCrit.text);
    final delai     = int.tryParse(_delaiModif.text);

    if (seuilEspA != null) data['seuil_alerte_especes'] = seuilEspA;
    if (seuilEspC != null) data['seuil_critique_especes'] = seuilEspC;
    if (seuilSimA != null) data['seuil_alerte_sim'] = seuilSimA;
    if (seuilSimC != null) data['seuil_critique_sim'] = seuilSimC;
    if (delai    != null) data['delai_modification_heures'] = delai;

    await p.mettreAJourConfigEntreprise(data);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Configuration enregistrée'),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
