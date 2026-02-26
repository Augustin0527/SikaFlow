import 'package:flutter/material.dart';

// Écran legacy - non utilisé dans la v2.0
// Les retraits sont maintenant gérés via OpérationsScreen
class RetraitsScreen extends StatelessWidget {
  const RetraitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E2530),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_upward_rounded,
                color: Color(0xFF8A9BB0), size: 48),
            SizedBox(height: 12),
            Text('Retraits',
                style: TextStyle(
                    color: Color(0xFFF0F4F8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'Consultez les opérations de retrait\ndans l\'écran Opérations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
