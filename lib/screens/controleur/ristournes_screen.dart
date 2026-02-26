import 'package:flutter/material.dart';

// Écran legacy contrôleur - ristournes gérées via écran gestionnaire
class RistournesScreen extends StatelessWidget {
  const RistournesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E2530),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.percent_outlined, color: Color(0xFF8A9BB0), size: 48),
            SizedBox(height: 12),
            Text('Ristournes',
                style: TextStyle(
                    color: Color(0xFFF0F4F8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'Disponible dans le tableau de bord gestionnaire',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
