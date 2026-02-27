import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ARCHITECTURE STABLE SIKAFLOW
// 1. Firebase.initializeApp() AWAITÉ avant runApp — garanti prêt
// 2. go_router pour URLs propres : /, /connexion, /admin, /gestionnaire…
// 3. Protection des routes dans le redirect go_router
// 4. Layout desktop responsive dans chaque dashboard
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisé de façon simple et garantie AVANT runApp
  await _initFirebase();

  runApp(const SikaFlowApp());
}

Future<void> _initFirebase() async {
  // Déjà initialisé (hot-reload web)
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('[SikaFlow] ✅ Firebase initialisé');
  } on FirebaseException catch (e) {
    // 'duplicate-app' = déjà initialisé, c'est OK
    if (e.code != 'duplicate-app') {
      if (kDebugMode) debugPrint('[SikaFlow] ⚠️ Firebase error: ${e.code} - ${e.message}');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[SikaFlow] ⚠️ Firebase init error: $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SikaFlowApp extends StatefulWidget {
  const SikaFlowApp({super.key});

  @override
  State<SikaFlowApp> createState() => _SikaFlowAppState();
}

class _SikaFlowAppState extends State<SikaFlowApp> {
  // AppProvider créé UNE SEULE FOIS ici
  final _provider = AppProvider();

  @override
  void initState() {
    super.initState();
    // Initialiser en arrière-plan (session persistante + authStateChanges)
    _provider.initialiser();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Builder(
        builder: (ctx) {
          // Le routeur est créé ici pour avoir accès au provider
          final router = createAppRouter(ctx.watch<AppProvider>());
          return MaterialApp.router(
            title: 'SikaFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

// ─── Écran de chargement (affiché par go_router pendant les redirections) ────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fade  = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(
                      color: AppTheme.accentOrange.withValues(alpha: 0.30 + 0.20 * _ctrl.value),
                      blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 8),
                    )],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.accentOrange,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SikaFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Opacity(
                opacity: _fade.value,
                child: const Text(
                  'Connexion en cours…',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  color: AppTheme.accentOrange,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
