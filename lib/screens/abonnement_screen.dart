import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AbonnementScreen extends StatefulWidget {
  final String entrepriseId;
  final Map<String, dynamic>? entrepriseData;
  const AbonnementScreen({super.key, required this.entrepriseId, this.entrepriseData});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  final _fs = FirestoreService();
  bool _chargement = false;
  String _modePaiement = 'mtn'; // mtn | moov | carte
  int _plan = 6; // 6 mois = 5000 FCFA
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pré-remplir si données disponibles
    if (widget.entrepriseData != null) {
      _emailCtrl.text = widget.entrepriseData!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  double get _montant => _plan == 6 ? 5000 : 10000;
  String get _description => _plan == 6
      ? 'SikaFlow - Abonnement 6 mois'
      : 'SikaFlow - Abonnement 12 mois';

  Future<void> _initierPaiementFedaPay() async {
    if (_nomCtrl.text.trim().isEmpty || _telCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le nom et le téléphone'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _chargement = true);

    try {
      // Appel API FedaPay pour initier le paiement
      // NOTE: En production, cette requête doit passer par votre backend sécurisé
      // pour ne pas exposer la clé secrète FedaPay
      final response = await http.post(
        Uri.parse('https://sandbox-api.fedapay.com/v1/transactions'),
        headers: {
          'Authorization': 'Bearer sk_sandbox_VOTRE_CLE_FEDAPAY', // ← À remplacer
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': _description,
          'amount': _montant.toInt(),
          'currency': {'iso': 'XOF'},
          'callback_url': 'https://sikaflow.bj/payment/callback',
          'customer': {
            'firstname': _nomCtrl.text.trim().split(' ').first,
            'lastname': _nomCtrl.text.trim().split(' ').length > 1
                ? _nomCtrl.text.trim().split(' ').last
                : '',
            'phone_number': {
              'number': _telCtrl.text.trim(),
              'country': 'BJ',
            },
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final transactionId = data['v1/transaction']?['id']?.toString();

        // Simulation : en prod, le webhook FedaPay confirme le paiement
        // Ici on simule une validation manuelle pour la démo
        if (transactionId != null) {
          await _fs.activerAbonnement(
            entrepriseId: widget.entrepriseId,
            type: 'semestriel',
            dureeMois: _plan,
            montant: _montant,
            modePaiement: 'fedapay',
            transactionId: transactionId,
          );
          if (mounted) _afficherSucces();
        }
      } else {
        _afficherErreur('Erreur FedaPay: ${response.statusCode}');
      }
    } catch (e) {
      // Mode démo si FedaPay non configuré
      _afficherModeDemoOuErreur(e.toString());
    }

    if (mounted) setState(() => _chargement = false);
  }

  void _afficherSucces() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text('Paiement réussi !', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Votre abonnement de $_plan mois est activé. Profitez pleinement de SikaFlow !',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Retour au tableau de bord', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherModeDemoOuErreur(String erreur) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Configuration requise', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Le paiement FedaPay nécessite une configuration des clés API en production.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Text('Étapes :', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('1. Créez un compte sur fedapay.com', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Text('2. Obtenez vos clés API (sandbox → production)', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Text('3. Remplacez "sk_sandbox_VOTRE_CLE_FEDAPAY" par votre clé', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Text('4. Configurez le webhook callback', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          const Text('En attendant, l\'admin peut activer votre abonnement manuellement.',
              style: TextStyle(color: Colors.orange, fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Compris')),
        ],
      ),
    );
  }

  void _afficherErreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        title: const Text('Abonnement SikaFlow', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Banner essai
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6E)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.star, color: Colors.orange, size: 32),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Passez à l\'abonnement SikaFlow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Synchronisation temps réel • Multi-agents • Rapports complets',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Choix plan
          const Text('Choisir un plan', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _planCard(6, '5 000 FCFA', '6 mois', 'Semestriel', Colors.blue),
            const SizedBox(width: 12),
            _planCard(12, '10 000 FCFA', '12 mois', 'Annuel (-17%)', Colors.purple),
          ]),
          const SizedBox(height: 24),

          // Mode de paiement
          const Text('Mode de paiement', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _paiementChip('mtn', 'MTN Money', Colors.yellow[700]!),
            const SizedBox(width: 8),
            _paiementChip('moov', 'Moov Money', Colors.blue),
            const SizedBox(width: 8),
            _paiementChip('carte', 'Carte', Colors.green),
          ]),
          const SizedBox(height: 24),

          // Infos client
          const Text('Vos coordonnées', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _champTexte(_nomCtrl, 'Nom complet *', Icons.person),
          const SizedBox(height: 12),
          _champTexte(_telCtrl, 'Numéro de téléphone *', Icons.phone, type: TextInputType.phone),
          const SizedBox(height: 12),
          _champTexte(_emailCtrl, 'Email (optionnel)', Icons.email, type: TextInputType.emailAddress),
          const SizedBox(height: 32),

          // Récapitulatif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(children: [
              _ligneRecap('Plan', '$_plan mois'),
              _ligneRecap('Montant', '${_montant.toStringAsFixed(0)} FCFA'),
              _ligneRecap('Paiement', _modePaiement.toUpperCase()),
              const Divider(color: Colors.white12),
              _ligneRecap('Total', '${_montant.toStringAsFixed(0)} FCFA', gras: true),
            ]),
          ),
          const SizedBox(height: 24),

          // Bouton paiement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _chargement
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.payment, color: Colors.white),
              label: Text(
                _chargement ? 'Traitement...' : 'Payer ${_montant.toStringAsFixed(0)} FCFA via FedaPay',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _chargement ? null : _initierPaiementFedaPay,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '🔒 Paiement sécurisé via FedaPay • Opérateurs béninois supportés',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _planCard(int mois, String prix, String duree, String label, Color couleur) {
    final selected = _plan == mois;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _plan = mois),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? couleur.withValues(alpha: 0.15) : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? couleur : Colors.white24, width: selected ? 2 : 1),
          ),
          child: Column(children: [
            if (selected) Icon(Icons.check_circle, color: couleur, size: 20),
            Text(prix, style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(duree, style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _paiementChip(String mode, String label, Color couleur) {
    final selected = _modePaiement == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modePaiement = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? couleur.withValues(alpha: 0.15) : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? couleur : Colors.white24),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: selected ? couleur : Colors.white54, fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _champTexte(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary)),
      ),
    );
  }

  Widget _ligneRecap(String label, String valeur, {bool gras = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: gras ? FontWeight.bold : FontWeight.normal)),
          Text(valeur, style: TextStyle(color: gras ? Colors.orange : Colors.white, fontSize: 13, fontWeight: gras ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
