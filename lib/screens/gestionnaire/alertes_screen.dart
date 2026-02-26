import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class AlertesScreen extends StatelessWidget {
  const AlertesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final alertes  = p.alertesNonLues;
      final demandes = p.demandesEnAttente;

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alertes & Demandes',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Demandes en attente
              if (demandes.isNotEmpty) ...[
                _sectionTitle('Demandes de rééquilibrage (${demandes.length})'),
                const SizedBox(height: 8),
                ...demandes.map((d) => _buildDemandeCard(ctx, p, d)),
                const SizedBox(height: 20),
              ],

              // Alertes
              _sectionTitle('Alertes actives (${alertes.length})'),
              const SizedBox(height: 8),
              if (alertes.isEmpty)
                _buildEmpty('Aucune alerte active',
                    'Tous vos stands sont dans les limites normales')
              else
                ...alertes.map((a) => _buildAlerteCard(ctx, p, a)),
            ],
          ),
        ),
      );
    });
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: _textSec, fontSize: 13, fontWeight: FontWeight.bold));

  Widget _buildDemandeCard(BuildContext ctx, AppProvider p, dynamic d) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pending_actions_rounded,
              color: Color(0xFFFFB300), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(d.standNom,
                style: const TextStyle(
                    color: _textPrim, fontWeight: FontWeight.bold)),
          ),
          Text('${fmt.format(d.montant)} FCFA',
              style: const TextStyle(
                  color: _orange, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(d.type.replaceAll('_', ' '),
            style: const TextStyle(color: _textSec, fontSize: 12)),
        Text('Par : ${d.agentNom} — ${d.motif}',
            style: const TextStyle(color: _textSec, fontSize: 11)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4444)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () async {
                await p.traiterDemandeReequilibrage(
                  demandeId: d.id, approuve: false,
                  motifRefus: 'Refusé',
                );
              },
              child: const Text('Refuser',
                  style: TextStyle(color: Color(0xFFFF4444))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () async {
                await p.traiterDemandeReequilibrage(
                  demandeId: d.id, approuve: true,
                );
              },
              child: const Text('Approuver',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildAlerteCard(BuildContext ctx, AppProvider p, dynamic a) {
    final isErr = a.estCritique;
    final color = isErr ? const Color(0xFFFF4444) : const Color(0xFFFFB300);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(isErr ? Icons.error_rounded : Icons.warning_amber_rounded,
            color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.standNom,
                style: const TextStyle(
                    color: _textPrim, fontWeight: FontWeight.bold)),
            Text(a.type.replaceAll('_', ' '),
                style: const TextStyle(color: _textSec, fontSize: 12)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: _textSec, size: 18),
          onPressed: () => p.marquerAlerteLue(a.id),
        ),
      ]),
    );
  }

  Widget _buildEmpty(String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: _success, size: 48),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: _textPrim,
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSec, fontSize: 12)),
        ]),
      ),
    );
  }
}
