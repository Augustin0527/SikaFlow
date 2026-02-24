import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminAbonnementScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> entreprises;
  const AdminAbonnementScreen({super.key, required this.entreprises});

  @override
  State<AdminAbonnementScreen> createState() => _AdminAbonnementScreenState();
}

class _AdminAbonnementScreenState extends State<AdminAbonnementScreen> {
  final _fs = FirestoreService();
  String? _entrepriseSelectionnee;
  int _dureeMois = 6;
  double _montant = 5000;
  bool _chargement = false;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _accorderAbonnement() async {
    if (_entrepriseSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une entreprise'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Confirmer l\'abonnement', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Entreprise: ${_nomEntreprise(_entrepriseSelectionnee!)}', style: const TextStyle(color: Colors.white70)),
          Text('Durée: $_dureeMois mois', style: const TextStyle(color: Colors.white70)),
          Text('Montant: ${_montant.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Colors.white70)),
          const Text('Mode: Manuel (Admin)', style: TextStyle(color: Colors.orange)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      setState(() => _chargement = true);
      await _fs.activerAbonnement(
        entrepriseId: _entrepriseSelectionnee!,
        type: 'semestriel',
        dureeMois: _dureeMois,
        montant: _montant,
        modePaiement: 'manuel',
        adminId: 'super_admin',
      );
      if (mounted) {
        setState(() => _chargement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Abonnement accordé avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  String _nomEntreprise(String id) {
    final e = widget.entreprises.where((e) => e.id == id).firstOrNull;
    if (e == null) return id;
    final data = e.data() as Map<String, dynamic>;
    return data['nom'] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        title: const Text('Abonnement Manuel', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Attribution manuelle d\'un abonnement par l\'administrateur. Le paiement a été reçu hors-ligne (Mobile Money, espèces...).',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Sélection entreprise
                const Text('Entreprise *', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _entrepriseSelectionnee,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Sélectionner une entreprise', style: TextStyle(color: Colors.white54)),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      items: widget.entreprises.map((e) {
                        final data = e.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(data['nom'] ?? e.id, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _entrepriseSelectionnee = v),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Durée
                const Text('Durée de l\'abonnement', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  _dureeChip(6, '6 mois\n5 000 FCFA'),
                  const SizedBox(width: 10),
                  _dureeChip(12, '12 mois\n10 000 FCFA'),
                  const SizedBox(width: 10),
                  _dureeChip(1, '1 mois\nEssai'),
                ]),
                const SizedBox(height: 20),

                // Montant
                const Text('Montant reçu (FCFA)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: _montant.toStringAsFixed(0)),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(color: Colors.white54),
                  ),
                  onChanged: (v) => _montant = double.tryParse(v) ?? _montant,
                ),
                const SizedBox(height: 20),

                // Notes
                const Text('Notes / Référence paiement', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ex: Paiement reçu via MTN le 12/01/2025...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Accorder l\'abonnement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _accorderAbonnement,
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _dureeChip(int mois, String label) {
    final selected = _dureeMois == mois;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dureeMois = mois;
            _montant = mois == 6 ? 5000 : mois == 12 ? 10000 : 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppTheme.primary : Colors.white24, width: selected ? 2 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? AppTheme.primary : Colors.white54, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
