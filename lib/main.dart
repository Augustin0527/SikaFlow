import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/changer_mdp_screen.dart';
import 'screens/gestionnaire/gestionnaire_dashboard.dart';
import 'screens/agent/agent_dashboard.dart';
import 'screens/controleur/controleur_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ARCHITECTURE "LANDING FIRST"
//
// Problème résolu : Firebase JS (gstatic.com) блокait le rendu de la landing
// pendant 2-8 secondes selon la connexion.
//
// Solution :
//   1. runApp() immédiat → la Landing Page s'affiche en < 500ms
//   2. Firebase s'initialise EN ARRIÈRE-PLAN (unawaited)
//   3. AppProvider attend que Firebase soit prêt via un Completer
//   4. La LandingPage ne fait AUCUN appel Firebase (données statiques)
//   5. Firebase n'est utilisé que lors de la connexion/inscription
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ① runApp() IMMÉDIAT → LandingPage affichée en < 500ms
  runApp(const SikaFlowApp());

  // ② Firebase s'initialise EN ARRIÈRE-PLAN (sans bloquer l'UI)
  _initFirebaseEnArrierePlan();
}

/// Initialise Firebase sans bloquer l'UI.
Future<void> _initFirebaseEnArrierePlan() async {
  if (Firebase.apps.isNotEmpty) return;

  final options = DefaultFirebaseOptions.currentPlatform;

  for (int tentative = 1; tentative <= 5; tentative++) {
    try {
      await Firebase.initializeApp(options: options);
      if (kDebugMode) debugPrint('[SikaFlow] ✅ Firebase prêt (tentative $tentative)');
      return;
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') return;
      if (kDebugMode) debugPrint('[SikaFlow] ⚠️ Firebase T$tentative: ${e.code}');
    } catch (e) {
      if (kDebugMode) debugPrint('[SikaFlow] ⚠️ Firebase T$tentative: $e');
    }
    if (tentative < 5) {
      await Future.delayed(Duration(seconds: tentative));
    }
  }
  if (kDebugMode) debugPrint('[SikaFlow] ❌ Firebase non initialisé après 5 tentatives');
}

// ─────────────────────────────────────────────────────────────────────────────
// Application principale
// ─────────────────────────────────────────────────────────────────────────────

class SikaFlowApp extends StatelessWidget {
  const SikaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'SikaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Routeur principal
// ─────────────────────────────────────────────────────────────────────────────

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        // Chargement en cours → splash (uniquement après tentative de login)
        if (provider.chargement) {
          return const _SplashScreen();
        }

        // Non connecté → LandingPage (affichage immédiat, pas de Firebase)
        if (!provider.estConnecte) {
          return const LandingPage();
        }

        final user = provider.utilisateurConnecte!;

        // Mot de passe provisoire → forcer changement
        if (user.motDePasseProvisoire) {
          return const ChangerMotDePasseScreen(obligatoire: true);
        }

        // Routage par rôle
        switch (user.role) {
          case 'super_admin':
            return const AdminDashboard();
          case 'gestionnaire':
            return const GestionnaireDashboard();
          case 'agent':
            return const AgentDashboard();
          case 'controleur':
            return const ControleurDashboard();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash screen animé (affiché uniquement pendant le login)
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange
                            .withValues(alpha: 0.30 + 0.20 * _ctrl.value),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 36,
                height: 36,
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
