import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class RistournesScreen extends StatelessWidget {
  const RistournesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final taux = p.tauxRistourne;
      // Calcul ristournes totales du mois
      final now = DateTime.now();
      final debutMois = DateTime(now.year, now.month, 1);
      final opsMois = p.operations
          .where((o) => o.dateHeure.isAfter(debutMois))
          .toList();
      final totalMois = opsMois.fold(0.0, (s, o) => s + o.ristourneCalculee);

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ristournes',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Carte résumé du mois
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ristournes du mois',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${fmt.format(totalMois)} FCFA',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${opsMois.length} opération(s)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Taux configurés
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Taux configurés',
                      style: TextStyle(
                          color: _textPrim,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: _orange),
                    onPressed: () => _showAddTauxDialog(ctx, p),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (taux.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Center(
                    child: Column(children: [
                      Icon(Icons.percent_outlined, color: _textSec, size: 32),
                      SizedBox(height: 8),
                      Text('Aucun taux configuré',
                          style: TextStyle(color: _textPrim)),
                      SizedBox(height: 4),
                      Text('Appuyez sur + pour ajouter un taux',
                          style: TextStyle(color: _textSec, fontSize: 12)),
                    ]),
                  ),
                )
              else
                ...taux.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.percent_rounded,
                          color: _orange, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${t.operateur} — ${t.typeOperation.replaceAll('_', ' ')}',
                              style: const TextStyle(
                                  color: _textPrim,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            'Depuis le ${DateFormat('dd/MM/yyyy').format(t.dateDebut)}',
                            style: const TextStyle(
                                color: _textSec, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text('${(t.taux * 100).toStringAsFixed(2)} %',
                        style: const TextStyle(
                            color: _success,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                )),
            ],
          ),
        ),
      );
    });
  }

  void _showAddTauxDialog(BuildContext ctx, AppProvider p) {
    final taux = TextEditingController();
    String operateur = 'MTN';
    String typeOp    = 'depot';

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(builder: (ctx2, ss) => AlertDialog(
        backgroundColor: const Color(0xFF252D3A),
        title: const Text('Ajouter un taux',
            style: TextStyle(color: Color(0xFFF0F4F8))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: operateur,
            dropdownColor: const Color(0xFF252D3A),
            style: const TextStyle(color: Color(0xFFF0F4F8)),
            decoration: InputDecoration(
              labelText: 'Opérateur',
              filled: true,
              fillColor: const Color(0xFF1E2530),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF313D52))),
            ),
            items: ['MTN', 'MOOV', 'CELTIIS']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => ss(() => operateur = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: typeOp,
            dropdownColor: const Color(0xFF252D3A),
            style: const TextStyle(color: Color(0xFFF0F4F8)),
            decoration: InputDecoration(
              labelText: 'Type d\'opération',
              filled: true,
              fillColor: const Color(0xFF1E2530),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF313D52))),
            ),
            items: [
              const DropdownMenuItem(value: 'depot', child: Text('Dépôt')),
              const DropdownMenuItem(value: 'retrait', child: Text('Retrait')),
              const DropdownMenuItem(
                  value: 'credit_forfait', child: Text('Crédit/Forfait')),
            ],
            onChanged: (v) => ss(() => typeOp = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: taux,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFFF0F4F8)),
            decoration: InputDecoration(
              labelText: 'Taux (%)',
              hintText: 'ex: 0.5',
              filled: true,
              fillColor: const Color(0xFF1E2530),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF313D52))),
              suffixText: '%',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF8A9BB0))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _orange),
            onPressed: () async {
              final v = double.tryParse(taux.text.replaceAll(',', '.'));
              if (v == null) return;
              await p.configurerTauxRistourne(
                operateur: operateur,
                typeOperation: typeOp,
                taux: v / 100,
                dateDebut: DateTime.now(),
              );
              if (ctx2.mounted) Navigator.pop(ctx2);
            },
            child: const Text('Enregistrer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }
}
