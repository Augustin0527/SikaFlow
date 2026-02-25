import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'models/user_model.dart';
import 'models/point_journalier.dart';
import 'models/ristourne.dart';
import 'models/retrait.dart';
import 'models/entreprise_model.dart';
import 'screens/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/changer_mdp_screen.dart';
import 'screens/gestionnaire/gestionnaire_dashboard.dart';
import 'screens/agent/agent_dashboard.dart';
import 'screens/controleur/controleur_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialisation Firebase ──────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // ── Hive : init avec gestion d'erreur (web compatible) ──────────────────
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(PointJournalierAdapter());
    Hive.registerAdapter(RistourneAdapter());
    Hive.registerAdapter(RetraitAdapter());
    Hive.registerAdapter(EntrepriseModelAdapter());

    await Hive.openBox<UserModel>('users');
    await Hive.openBox<PointJournalier>('points');
    await Hive.openBox<Ristourne>('ristournes');
    await Hive.openBox<Retrait>('retraits');
    await Hive.openBox<EntrepriseModel>('entreprises');
  } catch (e) {
    // Sur le web, Hive peut échouer si les boîtes sont corrompues → on efface
    debugPrint('Hive init error: $e — clearing storage...');
    try {
      await Hive.deleteFromDisk();
      await Hive.initFlutter();
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(PointJournalierAdapter());
      Hive.registerAdapter(RistourneAdapter());
      Hive.registerAdapter(RetraitAdapter());
      Hive.registerAdapter(EntrepriseModelAdapter());
      await Hive.openBox<UserModel>('users');
      await Hive.openBox<PointJournalier>('points');
      await Hive.openBox<Ristourne>('ristournes');
      await Hive.openBox<Retrait>('retraits');
      await Hive.openBox<EntrepriseModel>('entreprises');
    } catch (e2) {
      debugPrint('Hive recovery also failed: $e2');
    }
  }

  runApp(const SikaFlowApp());
}

class SikaFlowApp extends StatelessWidget {
  const SikaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _forceShow = false;

  @override
  void initState() {
    super.initState();
    // Sécurité : forcer l'affichage après 10 secondes max
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_forceShow) {
        setState(() => _forceShow = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        // Chargement initial (max 10s via _forceShow)
        if (provider.chargement && !provider.estConnecte && !_forceShow) {
          return const SplashScreen();
        }

        // Pas connecté → afficher la landing page
        if (!provider.estConnecte) {
          return const LandingPage();
        }

        final user = provider.utilisateurConnecte!;

        // Mot de passe provisoire → obliger le changement
        if (user.motDePasseProvisoire) {
          return const ChangerMotDePasseScreen(obligatoire: true);
        }

        // ── Routage par rôle ─────────────────────────────────────────────
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo SikaFlow
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.accentOrange,
                    size: 50,
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
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Système de gestion des opérations Mobile Money',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: AppTheme.accentOrange, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
