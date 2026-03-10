import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/plan_config_model.dart';
import '../models/landing_config_model.dart';
import '../router/app_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _featuresController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  final ScrollController _scrollController = ScrollController();
  bool _periodeAnnuelle = false;
  final _pricingFmt = NumberFormat('#,###', 'fr_FR');
  // Plans chargés immédiatement depuis les constantes (pas de Firebase au démarrage)
  // Mis à jour en arrière-plan depuis Firestore sans bloquer l'affichage
  List<PlanConfig> _plans = _plansStatiques();
  ConfigAbonnementGlobal _cfg = const ConfigAbonnementGlobal(
    dureeEssaiJours: 30,
    remiseAnnuelle: 0.20,
    essaiActif: true,
    messagePromo: '',
  );
  final bool _plansCharges = true;
  // Config dynamique landing (hero, contact, témoignages, footer)
  LandingConfig _landingConfig = LandingConfig.defaut();

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _featuresController.forward();
    });
    // Mise à jour silencieuse depuis Firestore
    _mettreAJourDepuisFirestore();
  }

  // Plans statiques hardcodés — affichés IMMÉDIATEMENT, sans attendre Firebase
  static List<PlanConfig> _plansStatiques() {
    return [
      const PlanConfig(
        code: 'solo', label: 'Solo', minStands: 1, maxStands: 1,
        prixMensuel: 1200, description: 'Parfait pour démarrer avec 1 stand',
        couleurHex: 0xFF4CAF50, actif: true, ordre: 1,
        features: ['1 stand', 'Tableau de bord complet', 'Gestion des opérations', 'Rapports journaliers', 'Support email'],
        populaire: false,
      ),
      const PlanConfig(
        code: 'pro', label: 'Pro', minStands: 2, maxStands: 5,
        prixMensuel: 5000, description: 'Pour les agences en croissance',
        couleurHex: 0xFFFF6B35, actif: true, ordre: 2,
        features: ['Jusqu\'à 5 stands', 'Tout le plan Solo', 'Multi-agents & contrôleurs', 'Alertes automatiques', 'Rapports avancés', 'Support prioritaire'],
        populaire: true,
      ),
      const PlanConfig(
        code: 'enterprise', label: 'Entreprise', minStands: 6, maxStands: -1,
        prixMensuel: 10000, description: 'Pour les grandes agences, stands illimités',
        couleurHex: 0xFFFFCC00, actif: true, ordre: 3,
        features: ['Stands illimités', 'Tout le plan Pro', 'API & intégrations', 'SLA garanti 99.9%', 'Gestionnaire dédié', 'Formation incluse'],
        populaire: false,
      ),
    ];
  }

  // Mise à jour silencieuse depuis Firestore (n'affecte pas le rendu initial)
  Future<void> _mettreAJourDepuisFirestore() async {
    // Attendre que Firebase soit prêt (plus long sur web)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Vérifier que Firebase est réellement initialisé avant tout appel
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return; // Firebase pas disponible
    }

    try {
      // Charger les plans d'abonnement
      final plans = await ConfigAbonnementService.chargerPlans();
      final cfg   = await ConfigAbonnementService.chargerGlobal();

      if (!mounted) return;

      // Charger la config landing dynamique
      final landingDoc = await FirebaseFirestore.instance
          .collection('config_landing')
          .doc('main')
          .get();

      if (!mounted) return;

      setState(() {
        final plansActifs = plans.where((p) => p.actif).toList();
        if (plansActifs.isNotEmpty) {
          _plans = plansActifs;
          _cfg   = cfg;
        }
        if (landingDoc.exists) {
          _landingConfig = LandingConfig.fromFirestore(landingDoc.data()!);
        }
      });
    } catch (e) {
      // Silencieux : la page fonctionne avec les données statiques
      // On ne propage pas l'erreur à l'UI
      if (kDebugMode) debugPrint('[LandingPage] Firestore update skipped: $e');
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _featuresController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.backgroundDark.withValues(alpha: 0.95),
            floating: true,
            snap: true,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.accentOrange,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SikaFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              // Bouton "Se Connecter" toujours visible (desktop + mobile)
              TextButton.icon(
                onPressed: () => context.go(Routes.connexion),
                icon: const Icon(Icons.login_rounded, size: 16, color: AppTheme.textSecondary),
                label: Text(
                  isWide ? 'Se Connecter' : 'Connexion',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed: () => context.go(Routes.inscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 20 : 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isWide ? 'S\'inscrire' : 'Essai',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),

          // ── Contenu principal ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroSection(isWide),
                _buildStatsBar(),
                _buildFeaturesSection(isWide),
                _buildHowItWorksSection(isWide),
                _buildRolesSection(isWide),
                _buildPricingSection(isWide),
                _buildOperateursSection(),
                _buildTemoignagesSection(isWide),
                _buildCTASection(),
                _buildFooter(isWide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(bool isWide) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundDark, AppTheme.primaryNavy],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOrange.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOrange.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 24,
              vertical: isWide ? 90 : 60,
            ),
            child: FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              flex: 6, child: _heroText()),
                          const SizedBox(width: 60),
                          Expanded(flex: 4, child: _heroPhone()),
                        ],
                      )
                    : Column(
                        children: [
                          _heroText(),
                          const SizedBox(height: 40),
                          _heroPhone(),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentOrange.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppTheme.accentOrange, size: 14),
              const SizedBox(width: 6),
              Text(
                _landingConfig.hero.sousTitre,
                style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _landingConfig.hero.titre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.accentGradient.createShader(bounds),
          child: Text(
            _landingConfig.hero.titreSuite,
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _landingConfig.hero.description,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.inscription),
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: Text(_landingConfig.hero.ctaPrimaire),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                elevation: 4,
                shadowColor:
                    AppTheme.accentOrange.withValues(alpha: 0.4),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.connexion),
              icon: const Icon(Icons.login, size: 18),
              label: Text(_landingConfig.hero.ctaSecondaire),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                    color: AppTheme.textSecondary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _heroBadge(Icons.shield_outlined, _landingConfig.hero.badgeEssai),
            const SizedBox(width: 24),
            _heroBadge(Icons.sync, _landingConfig.hero.badge2),
            const SizedBox(width: 24),
            _heroBadge(Icons.lock_outline, _landingConfig.hero.badge3),
          ],
        ),
      ],
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.accentOrange, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _heroPhone() {
    return Center(
      child: Container(
        width: 280,
        height: 520,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
              color: AppTheme.accentOrange.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentOrange.withValues(alpha: 0.15),
              blurRadius: 50,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Notch
            Container(
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            // Header simulé
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: Colors.white,
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.accentOrange,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SikaFlow',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('Dashboard Agent',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('En ligne',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Solde
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde du jour',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  const Text('850 000 FCFA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _phoneStatChip('↑ 12 ops', true),
                      const SizedBox(width: 8),
                      _phoneStatChip('+45k FCFA', true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Mini stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: _phoneMiniCard(
                          'MTN', '450k', AppTheme.mtnYellow)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _phoneMiniCard(
                          'Moov', '280k', AppTheme.moovBlue)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _phoneMiniCard(
                          'Celtiis', '120k', AppTheme.celtiisRed)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Transactions récentes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _phoneTxRow('Dépôt MTN', '+25 000', true),
                  _phoneTxRow('Retrait Moov', '-15 000', false),
                  _phoneTxRow('Dépôt Celtiis', '+8 500', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneStatChip(String text, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _phoneMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _phoneTxRow(String label, String amount, bool positive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: positive
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : AppTheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              positive ? Icons.arrow_downward : Icons.arrow_upward,
              color: positive ? AppTheme.success : AppTheme.error,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ),
          Text(
            amount,
            style: TextStyle(
              color: positive ? AppTheme.success : AppTheme.error,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATS BAR
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStatsBar() {
    return Container(
      color: AppTheme.cardDarker,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 16,
        spacing: 32,
        children: [
          for (int i = 0; i < _landingConfig.stats.length; i++) ...[
            if (i > 0) _dividerStat(),
            _statItem(_landingConfig.stats[i].valeur, _landingConfig.stats[i].label),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.accentGradient.createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900),
          ),
        ),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _dividerStat() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.divider,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FEATURES SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFeaturesSection(bool isWide) {
    // Icônes et couleurs hardcodées — seuls titres/descriptions viennent de Firestore
    const iconesCouleurs = [
      (Icons.sync_rounded, AppTheme.accentOrange),
      (Icons.verified_user_rounded, AppTheme.moovBlue),
      (Icons.people_alt_rounded, AppTheme.success),
      (Icons.bar_chart_rounded, AppTheme.mtnYellow),
      (Icons.account_balance_wallet_rounded, AppTheme.celtiisRed),
      (Icons.notifications_active_rounded, Color(0xFF9C27B0)),
    ];

    final defaut = LandingConfig.defaut();
    final featuresSource = _landingConfig.features.isNotEmpty
        ? _landingConfig.features
        : defaut.features;

    final features = List.generate(iconesCouleurs.length, (i) {
      final source = i < featuresSource.length ? featuresSource[i] : defaut.features[i];
      return _FeatureData(
        icon: iconesCouleurs[i].$1,
        color: iconesCouleurs[i].$2,
        title: source.titre,
        description: source.description,
      );
    });

    final header = _landingConfig.featuresHeader;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _sectionHeader(
            header.titre,
            header.badge,
            header.description,
          ),
          const SizedBox(height: 56),
          FadeTransition(
            opacity: _featuresController,
            child: isWide
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: features.length,
                    itemBuilder: (_, i) => _featureCard(features[i]),
                  )
                : Column(
                    children: features
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _featureCard(f),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(_FeatureData f) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(f.icon, color: f.color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            f.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            f.description,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HOW IT WORKS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHowItWorksSection(bool isWide) {
    // Icônes hardcodées — titres/descriptions viennent de Firestore
    const icones = [
      Icons.app_registration_rounded,
      Icons.group_add_rounded,
      Icons.trending_up_rounded,
    ];

    final defaut = LandingConfig.defaut();
    final etapesSource = _landingConfig.etapes.isNotEmpty
        ? _landingConfig.etapes
        : defaut.etapes;

    final header = _landingConfig.etapesHeader;

    return Container(
      color: AppTheme.cardDarker,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _sectionHeader(
            header.titre,
            header.badge,
            header.description,
          ),
          const SizedBox(height: 56),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < icones.length; i++) ...[
                      if (i > 0) _stepArrow(),
                      Expanded(
                        child: _stepCard(
                          i + 1,
                          icones[i],
                          i < etapesSource.length ? etapesSource[i].titre : defaut.etapes[i].titre,
                          i < etapesSource.length ? etapesSource[i].description : defaut.etapes[i].description,
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (int i = 0; i < icones.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      _stepCard(
                        i + 1,
                        icones[i],
                        i < etapesSource.length ? etapesSource[i].titre : defaut.etapes[i].titre,
                        i < etapesSource.length ? etapesSource[i].description : defaut.etapes[i].description,
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Widget _stepCard(int num, IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.accentOrange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$num',
                      style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _stepArrow() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Icon(Icons.arrow_forward_rounded,
          color: AppTheme.accentOrange.withValues(alpha: 0.5), size: 28),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ROLES SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRolesSection(bool isWide) {
    // Icônes et couleurs hardcodées — titres, sousTitres et permissions viennent de Firestore
    const iconesCouleurs = [
      (Icons.manage_accounts_rounded, AppTheme.accentOrange),
      (Icons.supervisor_account_rounded, AppTheme.success),
      (Icons.person_rounded, AppTheme.mtnYellow),
    ];

    final defaut = LandingConfig.defaut();
    final rolesSource = _landingConfig.roles.isNotEmpty
        ? _landingConfig.roles
        : defaut.roles;

    final roles = List.generate(iconesCouleurs.length, (i) {
      final source = i < rolesSource.length ? rolesSource[i] : defaut.roles[i];
      return _RoleData(
        icon: iconesCouleurs[i].$1,
        color: iconesCouleurs[i].$2,
        title: source.titre,
        subtitle: source.sousTitre,
        permissions: source.permissions,
      );
    });

    final header = _landingConfig.rolesHeader;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _sectionHeader(
            header.titre,
            header.badge,
            header.description,
          ),
          const SizedBox(height: 56),
          isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: roles
                      .map((r) => SizedBox(
                          width: 300,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _roleCard(r))))
                      .toList(),
                )
              : Column(
                  children: roles
                      .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _roleCard(r)))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _roleCard(_RoleData r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(r.icon, color: r.color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(r.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(r.subtitle,
              style: TextStyle(color: r.color, fontSize: 12)),
          const SizedBox(height: 12),
          ...r.permissions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: r.color, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PRICING SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPricingSection(bool isWide) {
    final remise = _cfg.remiseAnnuelle;
    final pct    = (remise * 100).round();
    final essaiJ = _cfg.dureeEssaiJours;

    return StatefulBuilder(
      builder: (ctx, setS) {
        return Container(
          color: AppTheme.cardDarker,
          padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 20, vertical: 80),
          child: Column(
            children: [
              _sectionHeader(
                'Transparent et abordable',
                'Tarification',
                'Prix basé sur le nombre de stands. $essaiJ jours d\'essai gratuit, sans carte bancaire.',
              ),
              const SizedBox(height: 36),

              // ── Toggle Mensuel / Annuel ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _periodeBtn('Mensuel', !_periodeAnnuelle, () {
                      setS(() => _periodeAnnuelle = false);
                      setState(() => _periodeAnnuelle = false);
                    }),
                    _periodeBtn(
                      pct > 0 ? 'Annuel  −$pct%' : 'Annuel',
                      _periodeAnnuelle,
                      () {
                        setS(() => _periodeAnnuelle = true);
                        setState(() => _periodeAnnuelle = true);
                      },
                      badge: pct > 0,
                    ),
                  ],
                ),
              ),

              // ── Message promo ────────────────────────────────────────────
              if (_cfg.messagePromo.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded,
                          color: AppTheme.accentOrange, size: 18),
                      const SizedBox(width: 10),
                      Flexible(child: Text(_cfg.messagePromo,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),

              // ── Cartes de plans ──────────────────────────────────────────
              if (!_plansCharges)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppTheme.accentOrange),
                )
              else if (_plans.isEmpty)
                const Text('Aucun plan disponible',
                    style: TextStyle(color: AppTheme.textSecondary))
              else
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _plans.asMap().entries.map((entry) {
                          final idx  = entry.key;
                          final plan = entry.value;
                          final isMiddle = idx == 1 && _plans.length == 3;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left:  idx == 0 ? 0 : 10,
                                right: idx == _plans.length - 1 ? 0 : 10,
                                top:   isMiddle ? 0 : 16, // plan central surlevé
                              ),
                              child: _pricingPlanCard(
                                plan, _periodeAnnuelle, remise,
                                elevated: isMiddle,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Column(
                        children: _plans.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _pricingPlanCard(
                              entry.value, _periodeAnnuelle, remise,
                              elevated: entry.key == 1 && _plans.length == 3,
                            ),
                          );
                        }).toList(),
                      ),

              const SizedBox(height: 40),

              // ── Bande essai gratuit ──────────────────────────────────────
              if (_cfg.essaiActif)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success.withValues(alpha: 0.08),
                        AppTheme.accentOrange.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: isWide
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$essaiJ JOURS GRATUITS',
                                style: const TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Text(
                                'Toutes les fonctionnalités incluses · Aucune carte bancaire requise · Annulez à tout moment',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    height: 1.5),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.go(Routes.inscription),
                              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                              label: const Text('Démarrer l\'essai'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$essaiJ JOURS GRATUITS',
                                style: const TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Toutes les fonctionnalités incluses\nAucune carte bancaire requise',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go(Routes.inscription),
                                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                                label: const Text('Démarrer l\'essai gratuit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

              const SizedBox(height: 24),
              // ── Info paiement ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment_rounded,
                        color: AppTheme.textSecondary, size: 18),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Paiement via MTN MoMo, Moov Money ou virement bancaire',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _periodeBtn(String label, bool selected, VoidCallback onTap,
      {bool badge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _pricingCardEssai() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('GRATUIT',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined,
                  color: AppTheme.textHint, size: 18),
              const SizedBox(width: 6),
              Text('${_cfg.dureeEssaiJours} jours',
                  style:
                      const TextStyle(color: AppTheme.textHint, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Période d\'essai',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Toutes les fonctionnalités incluses. Aucune carte bancaire requise.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _essaiBadge(Icons.check_circle_outline, 'Agents illimités'),
              _essaiBadge(Icons.check_circle_outline, 'Opérations illimitées'),
              _essaiBadge(Icons.check_circle_outline, 'Sync temps réel'),
              _essaiBadge(Icons.check_circle_outline, 'Tous les rôles'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(Routes.inscription),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Commencer gratuitement'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.success, width: 1.5),
                foregroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _essaiBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.success, size: 14),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _pricingPlanCard(PlanConfig plan, bool annuel, double remise,
      {bool elevated = false}) {
    final prixMensuel = annuel ? plan.prixMensuelAvecRemise(remise) : plan.prixMensuel;
    final prixOriginal = plan.prixMensuel;
    final totalAnnuel  = plan.totalPeriode(12, remise);
    final economie     = plan.economieAnnuelle(remise);
    final color        = Color(plan.couleurHex);
    // Badge populaire : depuis Firestore ou par défaut le plan central (index 1)
    final isPopular    = plan.populaire || elevated;

    // Features : depuis Firestore si dispo, sinon fallback
    final features = plan.features.isNotEmpty
        ? plan.features
        : _featuresParDefaut(plan);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPopular ? AppTheme.cardDark : AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? color.withValues(alpha: 0.7)
              : color.withValues(alpha: 0.30),
          width: isPopular ? 2 : 1.5,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge populaire ────────────────────────────────────────────
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text('POPULAIRE',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ],
              ),
            ),

          // ── En-tête plan ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconPourPlan(plan.code), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text(
                    plan.maxStands == -1
                        ? '${plan.minStands}+ stands'
                        : plan.minStands == plan.maxStands
                            ? '${plan.minStands} stand'
                            : '${plan.minStands}–${plan.maxStands} stands',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.description,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 20),

          // ── Prix ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _pricingFmt.format(prixMensuel),
                style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 3),
                child: Text(' F/mois',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
            ],
          ),
          if (annuel && remise > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              // Prix barré
              Text(
                '${_pricingFmt.format(prixOriginal)} F',
                style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough),
              ),
              const SizedBox(width: 8),
              // Total annuel
              Text(
                '${_pricingFmt.format(totalAnnuel)} F/an',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Text(
                '✓ Économie ${_pricingFmt.format(economie)} F/an',
                style: const TextStyle(
                    color: AppTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 18),
          Divider(color: color.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),

          // ── Features ───────────────────────────────────────────────────
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: color, size: 11),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                              height: 1.3)),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // ── Bouton CTA ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(Routes.inscription),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? color : color.withValues(alpha: 0.9),
                foregroundColor: plan.couleurHex == 0xFFFFCC00
                    ? const Color(0xFF1A1A00)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                elevation: isPopular ? 4 : 0,
                shadowColor: color.withValues(alpha: 0.3),
              ),
              child: Text(
                'Choisir ${plan.label}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconPourPlan(String code) {
    switch (code) {
      case 'solo':       return Icons.person_rounded;
      case 'pro':        return Icons.groups_rounded;
      case 'enterprise': return Icons.domain_rounded;
      default:           return Icons.storefront_rounded;
    }
  }

  List<String> _featuresParDefaut(PlanConfig plan) {
    // Fallback si pas de features dans Firestore
    final standsLabel = plan.maxStands == -1
        ? 'Stands illimités'
        : '${plan.minStands}–${plan.maxStands} stands actifs';
    return [
      standsLabel,
      'Agents & contrôleurs illimités',
      'Opérations illimitées',
      'Rapports et statistiques',
      'Alertes de solde',
    ];
  }

  Widget _planFeature(Color color, String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12))),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // OPERATEURS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildOperateursSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(
            'COMPATIBLE AVEC',
            style: TextStyle(
              color: AppTheme.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les 3 opérateurs Mobile Money du Bénin',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              _opLogoCard(
                name: 'MTN Mobile Money',
                logoAsset: 'assets/logos/mtn_momo.png',
                color: AppTheme.mtnYellow,
                bgColor: const Color(0xFFFFCC00),
                subtitle: 'MTN MoMo',
              ),
              _opLogoCard(
                name: 'Moov Money',
                logoAsset: 'assets/logos/moov_money.png',
                color: AppTheme.moovBlue,
                bgColor: const Color(0xFF0055A5),
                subtitle: 'Flooz',
              ),
              _opLogoCard(
                name: 'Celtiis Cash',
                logoAsset: 'assets/logos/celtiis_cash.png',
                color: AppTheme.celtiisRed,
                bgColor: const Color(0xFFE30613),
                subtitle: 'Celtiis Cash',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opLogoCard({
    required String name,
    required String logoAsset,
    required Color color,
    required Color bgColor,
    required String subtitle,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo circle avec image locale (asset)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  logoAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Text(
                      name.substring(0, 1),
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TÉMOIGNAGES SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildTemoignagesSection(bool isWide) {
    // Utiliser les témoignages depuis Firestore, filtrés (actifs)
    final temoignages = _landingConfig.temoignages.where((t) => t.actif).toList();
    if (temoignages.isEmpty) return const SizedBox.shrink();

    // Convertir TemoignageConfig → _TemoignageData pour réutiliser le widget existant
    final items = temoignages.map((t) => _TemoignageData(
      nom: t.nom,
      role: t.role,
      ville: t.ville,
      texte: t.texte,
      photoUrl: t.photoUrl,
      note: t.etoiles,
    )).toList();

    return Container(
      color: const Color(0xFF0D1221),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 60),
      child: Column(
        children: [
          _sectionHeader(
            'Ils nous font confiance',
            '⭐ Témoignages',
            'Des gestionnaires et agents à travers tout le Bénin utilisent SikaFlow chaque jour.',
          ),
          const SizedBox(height: 40),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((t) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _carteTemoignage(t),
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: items
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _carteTemoignage(t),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _carteTemoignage(_TemoignageData t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Étoiles
          Row(
            children: List.generate(5, (i) => Icon(
              i < t.note ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.accentOrange,
              size: 18,
            )),
          ),
          const SizedBox(height: 14),
          // Texte
          Text(
            '"${t.texte}"',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 14),
          // Auteur
          Row(
            children: [
              // Photo de profil
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  t.photoUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.accentOrange, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nom,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${t.role} • ${t.ville}',
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CTA SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildCTASection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _landingConfig.cta.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _landingConfig.cta.description,
            style: const TextStyle(
                color: Colors.white70, fontSize: 15, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.inscription),
                icon: const Icon(Icons.rocket_launch, size: 18),
                label: Text(_landingConfig.cta.btnPrimaire),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.connexion),
                icon: const Icon(Icons.login),
                label: Text(_landingConfig.cta.btnSecondaire),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side:
                      const BorderSide(color: Colors.white70, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(bool isWide) {
    return Container(
      color: AppTheme.cardDarker,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 48),
      child: Column(
        children: [
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _footerBrand()),
                    Expanded(flex: 2, child: _footerLinksCliquables('Produit', [
                      ('Fonctionnalités', () => _ouvrirDialogue(context, 'Fonctionnalités', _contenuFonctionnalites())),
                      ('Tarification', () => _scrollToSection('tarification')),
                      ('Sécurité', () => _ouvrirDialogue(context, 'Sécurité & Confidentialité', _contenuSecurite())),
                    ])),
                    Expanded(flex: 2, child: _footerLinksCliquables('Liens', [
                      ('À propos', () => _ouvrirDialogue(context, 'À propos de SikaFlow', _contenuAPropos())),
                      ('Nous contacter', () => _ouvrirContact(context)),
                      ('Conditions d\'utilisation', () => _ouvrirDialogue(context, 'Conditions d\'utilisation', _contenuCGU())),
                    ])),
                    Expanded(flex: 2, child: _footerContact()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footerBrand(),
                    const SizedBox(height: 24),
                    _footerLinksCliquables('Liens rapides', [
                      ('À propos', () => _ouvrirDialogue(context, 'À propos de SikaFlow', _contenuAPropos())),
                      ('Nous contacter', () => _ouvrirContact(context)),
                      ('Fonctionnalités', () => _ouvrirDialogue(context, 'Fonctionnalités', _contenuFonctionnalites())),
                      ('Conditions d\'utilisation', () => _ouvrirDialogue(context, 'Conditions d\'utilisation', _contenuCGU())),
                    ]),
                    const SizedBox(height: 24),
                    _footerContact(),
                  ],
                ),
          const SizedBox(height: 40),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _landingConfig.contact.copyrightTexte,
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                ),
              ),
              // Lien discret vers l'espace admin
              TextButton(
                onPressed: () => context.go(Routes.connexion),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: const Text(
                  'Espace Admin',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.accentOrange,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SikaFlow',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _landingConfig.contact.sloganFooter,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _socialIcon(Icons.language, _landingConfig.contact.siteWeb),
          ],
        ),
      ],
    );
  }

  Widget _footerLinksCliquables(String title, List<(String, VoidCallback)> liens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 14),
        ...liens.map((lien) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: lien.$2,
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  lien.$1,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.textHint),
                ),
              ),
            )),
      ],
    );
  }

  Widget _footerContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 14),
        _contactRowCliquable(Icons.email_outlined, _landingConfig.contact.email,
            () => _lancerUrl('mailto:${_landingConfig.contact.email}')),
        const SizedBox(height: 8),
        _contactRowCliquable(Icons.phone_outlined, _landingConfig.contact.telephone,
            () => _lancerUrl('tel:${_landingConfig.contact.telephone.replaceAll(' ', '')}')),
        const SizedBox(height: 8),
        _contactRowCliquable(Icons.location_on_outlined, '${_landingConfig.contact.ville}, ${_landingConfig.contact.pays}', null),
        const SizedBox(height: 8),
        _contactRowCliquable(Icons.web, _landingConfig.contact.siteWeb,
            () => _lancerUrl('https://${_landingConfig.contact.siteWeb}')),
      ],
    );
  }

  Widget _contactRowCliquable(IconData icon, String text, VoidCallback? onTap) {
    final widget = Row(
      children: [
        Icon(icon, color: AppTheme.accentOrange, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: onTap != null ? AppTheme.accentOrange : AppTheme.textSecondary,
                fontSize: 13,
                decoration: onTap != null ? TextDecoration.underline : null,
                decorationColor: AppTheme.accentOrange)),
      ],
    );
    if (onTap == null) return widget;
    return InkWell(onTap: onTap, child: widget);
  }

  Future<void> _lancerUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _scrollToSection(String section) {
    // Scroll vers la section tarification
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent * 0.75,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _ouvrirContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nous contacter',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Notre équipe est disponible pour vous aider.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            _boutonContact(Icons.email_rounded, 'Email', _landingConfig.contact.email,
                () => _lancerUrl('mailto:${_landingConfig.contact.email}?subject=Contact SikaFlow')),
            const SizedBox(height: 12),
            _boutonContact(Icons.chat_rounded, 'WhatsApp', _landingConfig.contact.whatsapp,
                () => _lancerUrl('https://wa.me/${_landingConfig.contact.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}?text=Bonjour, je vous contacte depuis SikaFlow')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _boutonContact(IconData icon, String titre, String sous, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentOrange, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(sous, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textHint, size: 14),
          ],
        ),
      ),
    );
  }

  void _ouvrirDialogue(BuildContext context, String titre, Widget contenu) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titre,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: contenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenuAPropos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ligneInfo('🏢', 'Entreprise', 'GFPEANC — Gestion Financière et Promotions des Entreprises Agricoles Non Conventionnelles'),
        const SizedBox(height: 12),
        _ligneInfo('📍', 'Siège', 'Cotonou, République du Bénin'),
        const SizedBox(height: 12),
        _ligneInfo('🎯', 'Mission', 'Digitaliser la gestion des agents Mobile Money en Afrique de l\'Ouest. Nous fournissons aux gestionnaires d\'agences Mobile Money les outils numériques pour suivre les performances, gérer les ristournes et assurer la transparence des opérations.'),
        const SizedBox(height: 12),
        _ligneInfo('💡', 'Vision', 'Devenir la plateforme de référence pour la gestion des réseaux d\'agents Mobile Money en Afrique sub-saharienne.'),
        const SizedBox(height: 12),
        _ligneInfo('🗓️', 'Fondé en', '2024 — Version actuelle : 1.0'),
        const SizedBox(height: 12),
        _ligneInfo('📧', 'Contact', 'contact@sikaflow.org'),
      ],
    );
  }

  Widget _contenuFonctionnalites() {
    final features = [
      ('📊', 'Points journaliers', 'Saisie quotidienne des soldes MTN, Moov, Celtiis et espèces par chaque agent.'),
      ('👥', 'Gestion des membres', 'Ajout d\'agents et contrôleurs avec invitation email automatique.'),
      ('💰', 'Ristournes automatiques', 'Calcul et attribution automatique des primes selon les performances.'),
      ('📈', 'Rapports & statistiques', 'Graphiques d\'évolution, synthèses quotidiennes et historiques complets.'),
      ('🔐', 'Multi-rôles sécurisé', 'Super Admin, Gestionnaire, Contrôleur, Agent — chaque rôle a ses accès.'),
      ('📱', 'Application mobile', 'Interface optimisée pour smartphones Android et iOS.'),
      ('☁️', 'Sauvegarde cloud', 'Données sauvegardées en temps réel sur Firebase Google.'),
      ('💳', 'Abonnements flexibles', 'Plans Starter, Business, Premium adaptés à chaque taille d\'agence.'),
    ];
    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(f.$3, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _contenuSecurite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ligneInfo('🔐', 'Authentification', 'Firebase Authentication — chiffrement SSL/TLS sur tous les échanges.'),
        const SizedBox(height: 12),
        _ligneInfo('☁️', 'Stockage', 'Google Firestore avec règles de sécurité — accès restreint par entreprise.'),
        const SizedBox(height: 12),
        _ligneInfo('🏦', 'Paiements', 'FedaPay — passerelle certifiée PCI-DSS pour l\'Afrique de l\'Ouest.'),
        const SizedBox(height: 12),
        _ligneInfo('🔑', 'Mots de passe', 'Hachage sécurisé Firebase — aucun mot de passe en clair stocké.'),
        const SizedBox(height: 12),
        _ligneInfo('📊', 'Isolation données', 'Chaque entreprise ne peut voir que ses propres données.'),
        const SizedBox(height: 12),
        _ligneInfo('📧', 'Invitations sécurisées', 'Lien de connexion unique envoyé par email Firebase — expire après utilisation.'),
      ],
    );
  }

  Widget _contenuCGU() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Acceptation des conditions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('En utilisant SikaFlow, vous acceptez les présentes conditions. L\'utilisation du service est réservée aux professionnels du Mobile Money au Bénin.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        const Text('2. Abonnements et paiements',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Les abonnements sont mensuels et renouvelables. Le paiement est traité par FedaPay. Aucun remboursement n\'est accordé après activation.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        const Text('3. Confidentialité des données',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('Vos données sont hébergées sur Google Firebase. SikaFlow ne revend aucune donnée personnelle. Vous restez propriétaire de vos données.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        const Text('4. Responsabilité',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('SikaFlow est un outil de gestion. L\'éditeur n\'est pas responsable des décisions financières prises sur la base des données affichées.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        const Text('5. Contact',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('Pour toute question : ${_landingConfig.contact.email} — ${_landingConfig.contact.ville}, ${_landingConfig.contact.pays}.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
      ],
    );
  }

  Widget _ligneInfo(String emoji, String label, String valeur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label :', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              const SizedBox(height: 2),
              Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title, String badge, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentOrange.withValues(alpha: 0.3)),
          ),
          child: Text(
            badge.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 15, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _FeatureData(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description});
}

class _RoleData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> permissions;
  const _RoleData(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.permissions});
}

class _TemoignageData {
  final String nom;
  final String role;
  final String ville;
  final String texte;
  final String photoUrl;
  final int note;
  const _TemoignageData({
    required this.nom,
    required this.role,
    required this.ville,
    required this.texte,
    required this.photoUrl,
    required this.note,
  });
}
