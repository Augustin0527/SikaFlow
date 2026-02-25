import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/abonnement_model.dart';

/// Service FedaPay — intégration REST API paiement mobile
/// Documentation : https://docs.fedapay.com/api-reference
class FedaPayService {
  // ── Clés API ─────────────────────────────────────────────────────────────
  static const String _publicKey  = 'pk_sandbox_2K2AondxI9XxopQtAuyObQou';
  static const String _secretKey  = 'sk_sandbox_0Sc5tu7Q6Q350sMOKnmGsp9U';
  static const String _baseUrl    = 'https://sandbox.fedapay.com/v1';
  static const String _checkoutUrl = 'https://sandbox.fedapay.com';

  // ── Headers d'authentification ────────────────────────────────────────────
  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ═══════════════════════════════════════════════════════════════
  // CRÉER UNE TRANSACTION
  // ═══════════════════════════════════════════════════════════════
  /// Crée une transaction FedaPay et retourne l'URL de paiement Checkout
  static Future<FedaPayResultat> creerTransaction({
    required PlanAbonnement plan,
    required String entrepriseId,
    required String gestionnaireId,
    required String nomGestionnaire,
    required String emailGestionnaire,
    required String nomEntreprise,
    String? callbackUrl,
  }) async {
    try {
      // 1. Créer le customer FedaPay
      final customerId = await _creerOuRecupererCustomer(
        email: emailGestionnaire,
        nom: nomGestionnaire,
      );

      if (customerId == null) {
        return FedaPayResultat.erreur('Impossible de créer le profil client FedaPay.');
      }

      // 2. Créer la transaction
      final body = {
        'description': 'Abonnement SikaFlow ${plan.nom} — $nomEntreprise',
        'amount': plan.prix,
        'currency': {'iso': 'XOF'},
        'callback_url': callbackUrl ?? 'https://sikaflow-c8869.web.app/payment-callback',
        'merchant_reference': '${entrepriseId}_${plan.code}_${DateTime.now().millisecondsSinceEpoch}',
        'custom_metadata': {
          'entreprise_id': entrepriseId,
          'gestionnaire_id': gestionnaireId,
          'plan': plan.code,
          'source': 'sikaflow_app',
        },
        'customer': {'id': customerId},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('FedaPay create transaction: ${response.statusCode}');
      debugPrint('FedaPay response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final txData = data['v1/transaction'] as Map<String, dynamic>?
            ?? data['transaction'] as Map<String, dynamic>?
            ?? data;

        final transactionId = (txData['id'] as num?)?.toInt() ?? 0;
        final reference = txData['reference'] as String? ?? '';
        final token = txData['token'] as String? ?? '';

        // URL de paiement Checkout FedaPay
        final urlPaiement = token.isNotEmpty
            ? '$_checkoutUrl/checkout/$token'
            : '$_checkoutUrl/checkout/$transactionId';

        return FedaPayResultat.succes(
          transactionId: transactionId.toString(),
          reference: reference,
          urlPaiement: urlPaiement,
          token: token,
        );
      } else {
        final error = jsonDecode(response.body);
        final msg = _extraireErreur(error);
        return FedaPayResultat.erreur(msg);
      }
    } catch (e) {
      debugPrint('FedaPay erreur création transaction: $e');
      return FedaPayResultat.erreur('Erreur réseau : $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VÉRIFIER LE STATUT D'UNE TRANSACTION
  // ═══════════════════════════════════════════════════════════════
  static Future<String?> verifierStatutTransaction(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/$transactionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final txData = data['v1/transaction'] as Map<String, dynamic>?
            ?? data['transaction'] as Map<String, dynamic>?
            ?? data;
        return txData['status'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('FedaPay vérification statut: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RÉCUPÉRER L'HISTORIQUE DES TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> listerTransactions({
    String? merchantReference,
    int limit = 10,
  }) async {
    try {
      var url = '$_baseUrl/transactions?limit=$limit&order_by=created_at&order=desc';
      if (merchantReference != null) {
        url += '&filters[merchant_reference]=$merchantReference';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['v1/transactions'] as List<dynamic>?
            ?? data['transactions'] as List<dynamic>?
            ?? [];
        return items.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('FedaPay lister transactions: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CRÉER / RÉCUPÉRER UN CUSTOMER FEDAPAY
  // ═══════════════════════════════════════════════════════════════
  static Future<int?> _creerOuRecupererCustomer({
    required String email,
    required String nom,
  }) async {
    try {
      // Chercher si le customer existe déjà
      final searchResp = await http.get(
        Uri.parse('$_baseUrl/customers?filters[email]=${Uri.encodeComponent(email)}'),
        headers: _headers,
      );

      if (searchResp.statusCode == 200) {
        final data = jsonDecode(searchResp.body) as Map<String, dynamic>;
        final items = data['v1/customers'] as List<dynamic>?
            ?? data['customers'] as List<dynamic>?
            ?? [];
        if (items.isNotEmpty) {
          return (items.first as Map<String, dynamic>)['id'] as int?;
        }
      }

      // Créer le customer
      final parts = nom.trim().split(' ');
      final prenom = parts.isNotEmpty ? parts.first : nom;
      final nomFamille = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final createResp = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'firstname': prenom,
          'lastname': nomFamille,
        }),
      );

      if (createResp.statusCode == 200 || createResp.statusCode == 201) {
        final data = jsonDecode(createResp.body) as Map<String, dynamic>;
        final customer = data['v1/customer'] as Map<String, dynamic>?
            ?? data['customer'] as Map<String, dynamic>?
            ?? data;
        return customer['id'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('FedaPay customer: $e');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _extraireErreur(dynamic error) {
    if (error is Map) {
      final errors = error['errors'];
      if (errors is Map) {
        final msgs = errors.values.expand((v) => v is List ? v : [v]).toList();
        if (msgs.isNotEmpty) return msgs.first.toString();
      }
      return error['message'] as String? ?? 'Erreur FedaPay inconnue';
    }
    return 'Erreur inconnue';
  }

  // ── URL Checkout publique (pour WebView) ──────────────────────────────────
  static String getCheckoutUrlPublic(String token) {
    return '$_checkoutUrl/checkout/$token?public_key=$_publicKey';
  }
}

// ── Résultat d'une opération FedaPay ─────────────────────────────────────────
class FedaPayResultat {
  final bool succes;
  final String? transactionId;
  final String? reference;
  final String? urlPaiement;
  final String? token;
  final String? erreur;

  const FedaPayResultat._({
    required this.succes,
    this.transactionId,
    this.reference,
    this.urlPaiement,
    this.token,
    this.erreur,
  });

  factory FedaPayResultat.succes({
    required String transactionId,
    required String reference,
    required String urlPaiement,
    String? token,
  }) => FedaPayResultat._(
    succes: true,
    transactionId: transactionId,
    reference: reference,
    urlPaiement: urlPaiement,
    token: token,
  );

  factory FedaPayResultat.erreur(String message) =>
      FedaPayResultat._(succes: false, erreur: message);
}
