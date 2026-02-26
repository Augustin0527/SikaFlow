import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class OperateurCard extends StatelessWidget {
  final String nom;
  final double montant;
  final LinearGradient gradient;
  final String icon;
  final AppProvider provider;

  const OperateurCard({
    super.key,
    required this.nom,
    required this.montant,
    required this.gradient,
    required this.icon,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sim_card_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                nom,
                style: TextStyle(
                  color: nom == 'MTN' ? Colors.black87 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat('#,###', 'fr_FR').format(montant) + ' FCFA',
              style: TextStyle(
                color: nom == 'MTN' ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
