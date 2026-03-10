/// Configuration des clés sensibles de SikaFlow.
///
/// Les clés sont injectées à la compilation via --dart-define :
///
///   flutter run \
///     --dart-define=FEDAPAY_PUBLIC_KEY=pk_live_xxx \
///     --dart-define=FEDAPAY_SECRET_KEY=sk_live_xxx \
///     --dart-define=FEDAPAY_ENV=live
///
/// En CI/CD (GitHub Actions), stocker ces valeurs dans les Secrets du dépôt.
/// NEVER commit les vraies clés dans le code source.
class AppConfig {
  AppConfig._();

  // ── FedaPay ──────────────────────────────────────────────────────────────
  static const String fedaPayPublicKey = String.fromEnvironment(
    'FEDAPAY_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String fedaPaySecretKey = String.fromEnvironment(
    'FEDAPAY_SECRET_KEY',
    defaultValue: '',
  );

  /// 'live' ou 'sandbox'
  static const String fedaPayEnv = String.fromEnvironment(
    'FEDAPAY_ENV',
    defaultValue: 'sandbox',
  );

  static bool get isLive => fedaPayEnv == 'live';

  static String get fedaPayBaseUrl => isLive
      ? 'https://live.fedapay.com/v1'
      : 'https://sandbox.fedapay.com/v1';

  static String get fedaPayCheckoutUrl => isLive
      ? 'https://live.fedapay.com'
      : 'https://sandbox.fedapay.com';

  /// Vérifie que les clés sont bien configurées au démarrage.
  static bool get isConfigured =>
      fedaPayPublicKey.isNotEmpty && fedaPaySecretKey.isNotEmpty;
}
