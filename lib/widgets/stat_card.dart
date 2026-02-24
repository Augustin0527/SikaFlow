import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color color;
  final String? sousTitre;

  const StatCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.color,
    this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            valeur,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(titre, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
          if (sousTitre != null)
            Text(sousTitre!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
