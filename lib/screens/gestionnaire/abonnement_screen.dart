import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/abonnement_model.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class AbonnementScreen extends StatelessWidget {
  const AbonnementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('dd/MM/yyyy');

    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final ent = p.entrepriseActive;
      final abonnements = p.abonnements;

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Abonnement',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Plan actuel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Plan actuel',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      ent?.statut ?? 'Essai gratuit',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
              if (ent?.dateFinEssai != null)
                      Text(
                        'Valide jusqu\'au ${DateFormat('dd/MM/yyyy').format(ent!.dateFinEssai!)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Historique abonnements
              const Text('Historique',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (abonnements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Center(
                    child: Column(children: [
                      Icon(Icons.receipt_long_outlined,
                          color: _textSec, size: 32),
                      SizedBox(height: 8),
                      Text('Aucun abonnement enregistré',
                          style: TextStyle(color: _textSec)),
                    ]),
                  ),
                )
              else
                ...abonnements.map((ab) => _buildAbonnementCard(ab)),

              const SizedBox(height: 24),

              // Contact support
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: const Row(children: [
                  Icon(Icons.support_agent_rounded,
                      color: _orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Besoin d\'aide ?',
                            style: TextStyle(
                                color: _textPrim,
                                fontWeight: FontWeight.bold)),
                        Text('Contactez le support SikaFlow',
                            style: TextStyle(
                                color: _textSec, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: _textSec, size: 14),
                ]),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAbonnementCard(AbonnementModel ab) {
    final actif = ab.statut == StatutAbonnement.actif;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: actif ? _success.withValues(alpha: 0.4) : _border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: (actif ? _success : _textSec).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            actif ? Icons.check_circle_rounded : Icons.history_rounded,
            color: actif ? _success : _textSec, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ab.plan.name,
                  style: const TextStyle(
                      color: _textPrim, fontWeight: FontWeight.bold)),
              Text('Statut: ${ab.statut.name}',
                  style: const TextStyle(color: _textSec, fontSize: 12)),
            ],
          ),
        ),
        if (actif)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Actif',
                style: TextStyle(
                    color: _success, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}
