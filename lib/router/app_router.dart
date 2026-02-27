// lib/router/app_router.dart
// Navigation go_router pour SikaFlow – URLs propres + protection des routes
// Routes : /, /connexion, /inscription, /mot-de-passe-oublie, /changer-mdp
//          /admin, /gestionnaire, /agent, /controleur

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_provider.dart';
import '../screens/landing_page.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/inscription_screen.dart';
import '../screens/auth/mot_de_passe_oublie_screen.dart';
import '../screens/auth/changer_mdp_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/gestionnaire/gestionnaire_dashboard.dart';
import '../screens/agent/agent_dashboard.dart';
import '../screens/controleur/controleur_dashboard.dart';

// ─── Clés de routes ───────────────────────────────────────────────────────────
class Routes {
  static const landing          = '/';
  static const connexion        = '/connexion';
  static const inscription      = '/inscription';
  static const motDePasseOublie = '/mot-de-passe-oublie';
  static const changerMdp       = '/changer-mdp';
  static const admin            = '/admin';
  static const gestionnaire     = '/gestionnaire';
  static const agent            = '/agent';
  static const controleur       = '/controleur';
}

// ─── Création du routeur (doit être réutilisé – pas recréé à chaque build) ────
GoRouter createAppRouter(AppProvider provider) {
  return GoRouter(
    initialLocation: Routes.landing,
    debugLogDiagnostics: false,

    // ── Redirection globale selon l'état d'authentification ──────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      final estConnecte   = provider.estConnecte;
      final chargement    = provider.chargement;
      final user          = provider.utilisateurConnecte;

      // Pendant le chargement, ne pas rediriger
      if (chargement) return null;

      // Pages publiques (ne nécessitent pas d'être connecté)
      final pagesPubliques = [
        Routes.landing,
        Routes.connexion,
        Routes.inscription,
        Routes.motDePasseOublie,
      ];

      // Si non connecté → landing ou connexion seulement
      if (!estConnecte) {
        if (pagesPubliques.contains(location)) return null;
        return Routes.connexion;
      }

      // Si connecté et mot de passe provisoire → forcer le changement
      if (user != null && user.motDePasseProvisoire) {
        if (location == Routes.changerMdp) return null;
        return Routes.changerMdp;
      }

      // Si connecté et sur une page publique → rediriger vers le bon dashboard
      if (pagesPubliques.contains(location)) {
        return _dashboardForRole(user?.role);
      }

      // Vérifier que l'utilisateur est sur le bon dashboard
      if (user != null) {
        final expectedDashboard = _dashboardForRole(user.role);
        if (location == Routes.changerMdp) return null;
        // Permettre l'accès à la route correspondant au rôle
        if (location.startsWith(expectedDashboard)) return null;
        // Sinon rediriger vers le bon dashboard
        return expectedDashboard;
      }

      return null;
    },

    // ── Rafraîchir la navigation quand l'état change ────────────────────────
    refreshListenable: provider,

    // ── Définition des routes ─────────────────────────────────────────────────
    routes: [
      // Landing page publique
      GoRoute(
        path: Routes.landing,
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),

      // Connexion
      GoRoute(
        path: Routes.connexion,
        name: 'connexion',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LoginScreen(emailPrerempli: email);
        },
      ),

      // Inscription
      GoRoute(
        path: Routes.inscription,
        name: 'inscription',
        builder: (context, state) => const InscriptionScreen(),
      ),

      // Mot de passe oublié
      GoRoute(
        path: Routes.motDePasseOublie,
        name: 'mot-de-passe-oublie',
        builder: (context, state) => const MotDePasseOublieScreen(),
      ),

      // Changer mot de passe
      GoRoute(
        path: Routes.changerMdp,
        name: 'changer-mdp',
        builder: (context, state) => const ChangerMotDePasseScreen(obligatoire: true),
      ),

      // Dashboard Super Admin
      GoRoute(
        path: Routes.admin,
        name: 'admin',
        builder: (context, state) => const AdminDashboard(),
      ),

      // Dashboard Gestionnaire
      GoRoute(
        path: Routes.gestionnaire,
        name: 'gestionnaire',
        builder: (context, state) => const GestionnaireDashboard(),
      ),

      // Dashboard Agent
      GoRoute(
        path: Routes.agent,
        name: 'agent',
        builder: (context, state) => const AgentDashboard(),
      ),

      // Dashboard Contrôleur
      GoRoute(
        path: Routes.controleur,
        name: 'controleur',
        builder: (context, state) => const ControleurDashboard(),
      ),
    ],

    // ── Page d'erreur ─────────────────────────────────────────────────────────
    errorBuilder: (context, state) => _ErrorPage(state.error),
  );
}

// ─── Helper : dashboard selon le rôle ─────────────────────────────────────────
String _dashboardForRole(String? role) {
  switch (role) {
    case 'super_admin':  return Routes.admin;
    case 'gestionnaire': return Routes.gestionnaire;
    case 'agent':        return Routes.agent;
    case 'controleur':   return Routes.controleur;
    default:             return Routes.connexion;
  }
}

// ─── Page d'erreur 404 ────────────────────────────────────────────────────────
class _ErrorPage extends StatelessWidget {
  final Exception? error;
  const _ErrorPage(this.error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2530),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B35), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Page introuvable',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? '404',
              style: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.landing),
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
