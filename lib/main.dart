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
// ARCHITECTURE SIMPLE ET FIABLE
// 1. Firebase.initializeApp() AWAITÉ avant runApp — garanti prêt
// 2. Landing page : données statiques → affichage immédiat
// 3. AppProvider : _chargement=false par défaut → pas de splash inutile
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisé de façon simple et garantie
  await _initFirebase();

  runApp(const SikaFlowApp());
}

Future<void> _initFirebase() async {
  // Déjà initialisé (hot-reload)
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

class SikaFlowApp extends StatelessWidget {
  const SikaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // initialiser() vérifie la session persistante et écoute authStateChanges
      create: (_) => AppProvider()..initialiser(),
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

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        if (provider.chargement) return const _SplashScreen();
        if (!provider.estConnecte) return const LandingPage();

        final user = provider.utilisateurConnecte!;
        if (user.motDePasseProvisoire) {
          return const ChangerMotDePasseScreen(obligatoire: true);
        }

        switch (user.role) {
          case 'super_admin':  return const AdminDashboard();
          case 'gestionnaire': return const GestionnaireDashboard();
          case 'agent':        return const AgentDashboard();
          case 'controleur':   return const ControleurDashboard();
          default:             return const LoginScreen();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fade  = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
                    child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: AppTheme.accentOrange, size: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('SikaFlow', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              Opacity(opacity: _fade.value,
                child: const Text('Connexion en cours…', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
              const SizedBox(height: 40),
              const SizedBox(width: 36, height: 36,
                child: CircularProgressIndicator(color: AppTheme.accentOrange, strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
