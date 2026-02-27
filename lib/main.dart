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
// Point d'entrée
// Architecture : Firebase est initialisé AVANT runApp().
// Cela garantit que firebase_core_web a fini de charger les scripts JS
// depuis gstatic.com avant que AppProvider ne soit créé.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec retry (le chargement JS peut prendre 1-3s sur Web)
  await _initFirebaseAvecRetry();

  runApp(const SikaFlowApp());
}

/// Tente d'initialiser Firebase jusqu'à 3 fois avec délais progressifs.
/// Sur Web, firebase_core_web charge les scripts via dynamic import()
/// ce qui peut prendre quelques secondes sur connexion lente.
Future<void> _initFirebaseAvecRetry() async {
  // Déjà initialisé (hot-reload Flutter dev) → on sort immédiatement
  if (Firebase.apps.isNotEmpty) {
    if (kDebugMode) debugPrint('[SikaFlow] Firebase déjà initialisé');
    return;
  }

  final options = DefaultFirebaseOptions.currentPlatform;

  for (int tentative = 1; tentative <= 3; tentative++) {
    try {
      await Firebase.initializeApp(options: options);
      if (kDebugMode) {
        debugPrint('[SikaFlow] ✅ Firebase initialisé (tentative $tentative)');
      }
      return; // Succès → on sort
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        if (kDebugMode) debugPrint('[SikaFlow] Firebase déjà initialisé (duplicate-app)');
        return; // C'est OK
      }
      if (kDebugMode) {
        debugPrint('[SikaFlow] ⚠️ FirebaseException T$tentative: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SikaFlow] ⚠️ Erreur T$tentative: $e');
      }
    }

    // Délai avant retry (0ms pour T1→T2, 2s pour T2→T3)
    if (tentative < 3) {
      final delai = tentative == 1
          ? const Duration(milliseconds: 1500)
          : const Duration(seconds: 2);
      if (kDebugMode) {
        debugPrint('[SikaFlow] ⏳ Attente ${delai.inMilliseconds}ms avant tentative ${tentative + 1}...');
      }
      await Future.delayed(delai);
    }
  }

  // Si les 3 tentatives échouent, on lance quand même l'app
  // AppProvider gèrera l'erreur proprement
  if (kDebugMode) {
    debugPrint('[SikaFlow] ❌ Firebase non initialisé après 3 tentatives — app lancée quand même');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Application principale
// ─────────────────────────────────────────────────────────────────────────────

class SikaFlowApp extends StatelessWidget {
  const SikaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // AppProvider est créé ICI, APRÈS Firebase.initializeApp() dans main()
      // donc _auth = FirebaseAuth.instance et _db = FirebaseFirestore.instance
      // sont toujours sûrs à appeler.
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
// Routeur principal
// ─────────────────────────────────────────────────────────────────────────────

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        // Chargement en cours → splash
        if (provider.chargement) {
          return const _SplashScreen();
        }

        // Non connecté → LandingPage avec les plans
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
// Splash screen animé
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
                  'Gestion Mobile Money',
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
