import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/operation_model.dart';
import '../../models/stand_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'stands_screen.dart';
import 'membres_screen.dart';
import 'rapports_screen.dart';
import 'operations_screen.dart';
import 'alertes_screen.dart';
import 'ristournes_screen.dart';
import 'config_screen.dart';

// ─── Constantes de couleur dark-mode ────────────────────────────────────────
const _bg        = Color(0xFF1E2530);
const _surface   = Color(0xFF252D3A);
const _surfaceHi = Color(0xFF2C3547);
const _border    = Color(0xFF313D52);
const _orange    = Color(0xFFFF6B35);
const _orangeGlow= Color(0xFFFF9500);
const _success   = Color(0xFF00C896);
const _warning   = Color(0xFFFFB300);
const _error     = Color(0xFFFF4444);
const _textPrim  = Color(0xFFF0F4F8);
const _textSec   = Color(0xFF8A9BB0);
const _sidebar   = Color(0xFF1A2130);

class GestionnaireDashboard extends StatefulWidget {
  const GestionnaireDashboard({super.key});

  @override
  State<GestionnaireDashboard> createState() => _GestionnaireDashboardState();
}

class _GestionnaireDashboardState extends State<GestionnaireDashboard>
    with SingleTickerProviderStateMixin {
  int _pageIndex = 0;
  bool _sidebarOpen = false;
  late AnimationController _sidebarAnim;
  late Animation<double> _slideAnim;
  final _fmt = NumberFormat('#,###', 'fr_FR');

  String _fmtF(double v) => '${_fmt.format(v)} FCFA';

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Tableau de bord'),
    _NavItem(Icons.store_rounded, Icons.store_outlined, 'Stands'),
    _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Opérations'),
    _NavItem(Icons.people_alt_rounded, Icons.people_alt_outlined, 'Membres'),
    _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Rapports'),
    _NavItem(Icons.percent_rounded, Icons.percent_outlined, 'Ristournes'),
    _NavItem(Icons.notifications_active_rounded, Icons.notifications_outlined, 'Alertes'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Configuration'),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnim = CurvedAnimation(parent: _sidebarAnim, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().rafraichir();
    });
  }

  @override
  void dispose() {
    _sidebarAnim.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarAnim.forward();
    } else {
      _sidebarAnim.reverse();
    }
  }

  void _selectPage(int index) {
    setState(() {
      _pageIndex = index;
      _sidebarOpen = false;
    });
    _sidebarAnim.reverse();
  }

  Widget _buildPage(AppProvider p) {
    switch (_pageIndex) {
      case 0: return _buildDashboardPage(p);
      case 1: return const StandsScreen();
      case 2: return const OperationsScreen();
      case 3: return const MembresScreen();
      case 4: return const RapportsScreen();
      case 5: return const RistournesScreen();
      case 6: return const AlertesScreen();
      case 7: return const ConfigScreen();
      default: return _buildDashboardPage(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final user    = p.utilisateurConnecte!;
      final ent     = p.entrepriseActive;
      final alertes = p.alertesNonLues;
      final demandes = p.demandesEnAttente;
      final notifCount = alertes.length + demandes.length;

      return Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // ── Contenu principal ──────────────────────────────────────────
            Column(
              children: [
                // AppBar custom
                _buildAppBar(user.prenom, ent?.nom, notifCount, p),
                // Body
                Expanded(
                  child: _buildPage(p),
                ),
              ],
            ),

            // ── Overlay sidebar ────────────────────────────────────────────
            if (_sidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),

            // ── Sidebar ────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(-280 * (1 - _slideAnim.value), 0),
                child: _buildSidebar(user.prenom, user.nom, ent?.nom, p),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(
      String prenom, String? entNom, int notifCount, AppProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: _sidebar,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Burger
              _IconBtn(
                icon: Icons.menu_rounded,
                onTap: _toggleSidebar,
                badge: notifCount > 0 ? notifCount : null,
              ),
              const SizedBox(width: 12),
              // Logo + titre
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_orange, _orangeGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entNom ?? 'SikaFlow',
                      style: const TextStyle(
                        color: _textPrim, fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Bonjour, $prenom',
                        style: const TextStyle(color: _textSec, fontSize: 11)),
                  ],
                ),
              ),
              // Notifications
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () => _voirNotifications(p),
                badge: notifCount > 0 ? notifCount : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────
  Widget _buildSidebar(
      String prenom, String nom, String? entNom, AppProvider p) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          // En-tête profil
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_orange, _orangeGlow]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${prenom.isNotEmpty ? prenom[0] : '?'}${nom.isNotEmpty ? nom[0] : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$prenom $nom',
                                style: const TextStyle(
                                  color: _textPrim,
                                  fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Gestionnaire',
                                  style: TextStyle(
                                    color: _orange, fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _textSec, size: 20),
                        onPressed: _toggleSidebar,
                      ),
                    ],
                  ),
                  if (entNom != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _surfaceHi,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.business_rounded,
                            color: _textSec, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(entNom,
                              style: const TextStyle(
                                  color: _textSec, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(color: _border, height: 1),
          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = _pageIndex == i;
                return _buildNavItem(item, i, selected, p);
              },
            ),
          ),

          // Déconnexion
          const Divider(color: _border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: InkWell(
                onTap: () {
                  p.seDeconnecter();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _error.withValues(alpha: 0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.logout_rounded, color: _error, size: 20),
                    SizedBox(width: 12),
                    Text('Déconnexion',
                        style: TextStyle(
                            color: _error, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index, bool selected, AppProvider p) {
    // Badge pour alertes
    int? badge;
    if (index == 6) {
      final n = p.alertesNonLues.length + p.demandesEnAttente.length;
      if (n > 0) badge = n;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _selectPage(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _orange.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: _orange.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(children: [
            Icon(
              selected ? item.iconActive : item.icon,
              color: selected ? _orange : _textSec,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    color: selected ? _textPrim : _textSec,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  )),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Page Dashboard ─────────────────────────────────────────────────────────
  Widget _buildDashboardPage(AppProvider p) {
    final stands = p.standsActifs;
    final totalEspeces = stands.fold(0.0, (s, st) => s + st.soldeEspeces);
    final totalSim = stands.fold(0.0, (s, st) => s + st.soldeTotalSim);
    final totalCapital = totalEspeces + totalSim;

    // Opérations aujourd'hui
    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day);
    final opsAujourd = p.operations.where((o) =>
        o.dateHeure.isAfter(debutJour)).toList();
    final nbOps = opsAujourd.length;
    final volumeJour = opsAujourd.fold(0.0, (s, o) => s + o.montant);
    final commissions = opsAujourd.fold(0.0, (s, o) => s + o.ristourneCalculee);

    // Alertes actives
    final nbAlertes = p.alertesNonLues.length;
    final nbDemandes = p.demandesEnAttente.length;

    return RefreshIndicator(
      color: _orange,
      backgroundColor: _surface,
      onRefresh: p.rafraichir,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre ────────────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tableau de bord',
                          style: TextStyle(
                            color: _textPrim,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )),
                      Text('Vue d\'ensemble de votre activité',
                          style: TextStyle(color: _textSec, fontSize: 12)),
                    ],
                  ),
                ),
                _buildDateBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // ── Capital global ─────────────────────────────────────────────
            _buildCapitalCard(totalCapital, totalEspeces, totalSim, stands.length),
            const SizedBox(height: 16),

            // ── KPIs du jour ───────────────────────────────────────────────
            _buildKpiRow(nbOps, volumeJour, commissions, nbAlertes + nbDemandes),
            const SizedBox(height: 20),

            // ── Demandes en attente ───────────────────────────────────────
            if (p.demandesEnAttente.isNotEmpty) ...[
              _buildDemandesWidget(p),
              const SizedBox(height: 20),
            ],

            // ── Section Stands ────────────────────────────────────────────
            _buildSectionHeader(
              'Mes stands actifs',
              '${stands.length}',
              onTap: () => _selectPage(1),
            ),
            const SizedBox(height: 10),
            if (stands.isEmpty)
              _buildEmptyStands()
            else
              ...stands.map((s) => _buildStandCard(s, p)),

            // ── Opérations récentes ───────────────────────────────────────
            if (opsAujourd.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(
                'Opérations récentes',
                "Aujourd'hui",
                onTap: () => _selectPage(2),
              ),
              const SizedBox(height: 10),
              ...opsAujourd.take(5).map((op) => _buildOperationTile(op)),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge() {
    final now = DateTime.now();
    final jours = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final mois = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: _orange, size: 14),
        const SizedBox(width: 6),
        Text(
          '${jours[now.weekday % 7]} ${now.day} ${mois[now.month - 1]}',
          style: const TextStyle(color: _textSec, fontSize: 12),
        ),
      ]),
    );
  }

  // ── Carte capital ──────────────────────────────────────────────────────────
  Widget _buildCapitalCard(
      double total, double especes, double sim, int nbStands) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Capital total',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$nbStands stand${nbStands > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fmtF(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStat2(
                      'Espèces', _fmtF(especes),
                      Icons.payments_outlined, Colors.white),
                ),
                Container(
                  width: 1, height: 36,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildMiniStat2(
                      'SIM Mobile', _fmtF(sim),
                      Icons.sim_card_outlined, Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat2(
      String label, String valeur, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(height: 4),
        Text(valeur,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.7), fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── KPIs ───────────────────────────────────────────────────────────────────
  Widget _buildKpiRow(
      int nbOps, double volume, double commissions, int nbAlertes) {
    return Row(
      children: [
        Expanded(child: _buildKpiCard(
          'Opérations\naujourd\'hui',
          '$nbOps',
          Icons.swap_horiz_rounded, _orange, false)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiCard(
          'Volume\ndu jour',
          _fmtF(volume),
          Icons.trending_up_rounded, _success, false)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiCard(
          'Ristournes\nestimées',
          _fmtF(commissions),
          Icons.percent_rounded, const Color(0xFF8B5CF6), false)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiCard(
          'Alertes\nactives',
          '$nbAlertes',
          Icons.notifications_active_rounded,
          nbAlertes > 0 ? _error : _success, nbAlertes > 0)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String valeur, IconData icon,
      Color color, bool pulse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: pulse ? color.withValues(alpha: 0.5) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(valeur,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: _textSec, fontSize: 10, height: 1.3),
              maxLines: 2),
        ],
      ),
    );
  }

  // ── Demandes ───────────────────────────────────────────────────────────────
  Widget _buildDemandesWidget(AppProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.pending_actions_rounded,
                color: _warning, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${p.demandesEnAttente.length} demande(s) de rééquilibrage en attente',
                style: const TextStyle(
                    color: _warning,
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => _voirDemandes(p),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: _warning.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Traiter',
                  style: TextStyle(color: _warning, fontSize: 12)),
            ),
          ]),
          ...p.demandesEnAttente.take(2).map((d) => Padding(
            padding: const EdgeInsets.only(top: 6, left: 26),
            child: Row(children: [
              const Icon(Icons.circle, color: _warning, size: 5),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${d.standNom} — ${d.type.replaceAll('_', ' ')} '
                  '${_fmt.format(d.montant)} FCFA',
                  style: const TextStyle(
                      color: _textSec, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String titre, String badge,
      {required VoidCallback onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(titre,
              style: const TextStyle(
                  color: _textPrim,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _orange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Text(badge,
                  style: const TextStyle(
                      color: _orange, fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _orange, size: 10),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStands() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_business_rounded,
              color: _orange, size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Aucun stand créé',
            style: TextStyle(
                color: _textPrim, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        const Text(
          'Créez vos premiers stands Mobile Money\npour commencer à suivre votre activité',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSec, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          label: const Text('Créer un stand',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          onPressed: () => _selectPage(1),
        ),
      ]),
    );
  }

  // ── Stand card ─────────────────────────────────────────────────────────────
  Widget _buildStandCard(StandModel stand, AppProvider p) {
    final ent = p.entrepriseActive;
    final niveauEsp = stand.niveauAlerteEspeces(
      ent?.seuilAlerteEspeces ?? 50000,
      ent?.seuilCritiqueEspeces ?? 20000,
    );
    final couleurEsp = niveauEsp == 'critique'
        ? _error
        : niveauEsp == 'alerte'
            ? _warning
            : _success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        // Entête
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _orange.withValues(alpha: 0.2),
                    _orangeGlow.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded, color: _orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stand.nom,
                      style: const TextStyle(
                        color: _textPrim,
                        fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        color: _textSec, size: 12),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(stand.lieu,
                          style: const TextStyle(
                              color: _textSec, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            if (stand.agentActuelNom != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _success.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_rounded,
                      color: _success, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    stand.agentActuelNom!.split(' ').first,
                    style: const TextStyle(
                        color: _success, fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _textSec.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Sans agent',
                    style: TextStyle(color: _textSec, fontSize: 11)),
              ),
          ]),
        ),

        // Divider stylé
        Container(height: 1, color: _border),

        // Soldes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Espèces
              Expanded(
                child: _buildSoldeChip(
                  'Espèces',
                  _fmtF(stand.soldeEspeces),
                  Icons.payments_rounded,
                  couleurEsp,
                ),
              ),
              const SizedBox(width: 8),
              // SIM par opérateur
              ...Operateur.values.map((op) => Expanded(
                child: _buildSoldeChip(
                  op.code,
                  _fmtF(stand.soldeSim(op.code)),
                  Icons.sim_card_rounded,
                  Color(op.couleurHex),
                ),
              )),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSoldeChip(
      String label, String valeur, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label,
            style: TextStyle(color: color, fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(valeur,
            style: const TextStyle(
              color: _textPrim, fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Opération tile ─────────────────────────────────────────────────────────
  Widget _buildOperationTile(OperationModel op) {
    final icons = {
      'depot': Icons.arrow_downward_rounded,
      'retrait': Icons.arrow_upward_rounded,
      'credit_forfait': Icons.phone_android_rounded,
    };
    final colors = {
      'depot': _success,
      'retrait': _error,
      'credit_forfait': const Color(0xFF8B5CF6),
    };
    final color = colors[op.typeOperation] ?? _textSec;
    final icon  = icons[op.typeOperation] ?? Icons.swap_horiz_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${op.operateur} — ${op.typeOperation.replaceAll('_', ' ')}',
                style: const TextStyle(
                    color: _textPrim,
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(op.standNom ?? '',
                  style: const TextStyle(color: _textSec, fontSize: 11)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmtF(op.montant),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            DateFormat('HH:mm').format(op.dateHeure),
            style: const TextStyle(color: _textSec, fontSize: 11),
          ),
          if (op.ristourneCalculee > 0)
            Text('+${NumberFormat('#,###', 'fr_FR').format(op.ristourneCalculee)} FCFA',
                style: const TextStyle(color: _success, fontSize: 10)),
        ]),
      ]),
    );
  }

  // ── Modals ─────────────────────────────────────────────────────────────────
  void _voirNotifications(AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Icon(Icons.notifications_outlined, color: _orange),
              SizedBox(width: 10),
              Text('Notifications',
                  style: TextStyle(
                      color: _textPrim, fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          if (p.demandesEnAttente.isEmpty && p.alertesNonLues.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: _success, size: 40),
                SizedBox(height: 8),
                Text('Aucune notification',
                    style: TextStyle(color: _textSec)),
              ]),
            ),
          if (p.demandesEnAttente.isNotEmpty)
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pending_actions_rounded,
                    color: _warning, size: 18),
              ),
              title: Text(
                '${p.demandesEnAttente.length} demande(s) de rééquilibrage',
                style: const TextStyle(color: _textPrim, fontSize: 13)),
              subtitle: const Text('En attente de votre décision',
                  style: TextStyle(color: _textSec, fontSize: 11)),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _voirDemandes(p);
                },
                child: const Text('Traiter',
                    style: TextStyle(color: _warning)),
              ),
            ),
          ...p.alertesNonLues.take(5).map((a) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (a.estCritique ? _error : _warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                a.estCritique
                    ? Icons.error_rounded
                    : Icons.warning_amber_rounded,
                color: a.estCritique ? _error : _warning, size: 18,
              ),
            ),
            title: Text(a.standNom,
                style: const TextStyle(color: _textPrim, fontSize: 13)),
            subtitle: Text(a.type.replaceAll('_', ' '),
                style: const TextStyle(color: _textSec, fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: _textSec, size: 18),
              onPressed: () => p.marquerAlerteLue(a.id),
            ),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _voirDemandes(AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Icon(Icons.pending_actions_rounded, color: _warning),
              SizedBox(width: 10),
              Text('Demandes de rééquilibrage',
                  style: TextStyle(
                      color: _textPrim, fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.demandesEnAttente.length,
              itemBuilder: (_, i) {
                final d = p.demandesEnAttente[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surfaceHi,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(d.standNom,
                              style: const TextStyle(
                                  color: _textPrim,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text('${_fmt.format(d.montant)} FCFA',
                            style: const TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        '${d.type.replaceAll('_', ' ')}'
                        '${d.operateurSource != null ? ' — ${d.operateurSource}' : ''}'
                        '${d.operateurDestination != null ? ' → ${d.operateurDestination}' : ''}',
                        style: const TextStyle(
                            color: _textSec, fontSize: 12),
                      ),
                      Text('Par : ${d.agentNom}',
                          style: const TextStyle(
                              color: _textSec, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('Motif : ${d.motif}',
                          style: const TextStyle(
                              color: _textSec, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _error),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              await p.traiterDemandeReequilibrage(
                                demandeId: d.id,
                                approuve: false,
                                motifRefus: 'Refusé par le gestionnaire',
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Refuser',
                                style: TextStyle(color: _error)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _success,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              await p.traiterDemandeReequilibrage(
                                demandeId: d.id,
                                approuve: true,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Approuver',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData iconActive;
  final IconData icon;
  final String label;
  const _NavItem(this.iconActive, this.icon, this.label);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  const _IconBtn({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF252D3A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF313D52)),
            ),
            child: Icon(icon, color: const Color(0xFFF0F4F8), size: 20),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -4, top: -4,
            child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF4444), shape: BoxShape.circle),
              child: Center(
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }
}
