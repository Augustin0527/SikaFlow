import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/operation_model.dart';
import '../../models/entreprise_model.dart';
import '../../theme/app_theme.dart';
import '../gestionnaire/stands_screen.dart';
import '../gestionnaire/operations_screen.dart';
import '../gestionnaire/membres_screen.dart';
import '../gestionnaire/alertes_screen.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _error    = Color(0xFFFF4444);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);
const _sidebar  = Color(0xFF1A2130);

class ControleurDashboard extends StatefulWidget {
  const ControleurDashboard({super.key});

  @override
  State<ControleurDashboard> createState() => _ControleurDashboardState();
}

class _ControleurDashboardState extends State<ControleurDashboard> {
  int _pageIndex = 0;
  final _fmt = NumberFormat('#,###', 'fr_FR');

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Tableau de bord'),
    _NavItem(Icons.store_rounded, Icons.store_outlined, 'Stands'),
    _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Opérations'),
    _NavItem(Icons.people_alt_rounded, Icons.people_alt_outlined, 'Membres'),
    _NavItem(Icons.notifications_active_rounded, Icons.notifications_outlined, 'Alertes'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().rafraichir();
    });
  }

  Widget _buildPage(AppProvider p) {
    switch (_pageIndex) {
      case 0: return _buildDashboard(p);
      case 1: return const StandsScreen();
      case 2: return const OperationsScreen();
      case 3: return const MembresScreen();
      case 4: return const AlertesScreen();
      default: return _buildDashboard(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final user = p.utilisateurConnecte!;
      final ent  = p.entrepriseActive;

      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _sidebar,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: _textPrim),
            onPressed: () => _showDrawer(ctx, p),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ent?.nom ?? 'SikaFlow',
                  style: const TextStyle(
                      color: _textPrim, fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('Contrôleur — ${user.prenom}',
                  style: const TextStyle(color: _textSec, fontSize: 11)),
            ],
          ),
          actions: [
            if (p.alertesNonLues.isNotEmpty ||
                p.demandesEnAttente.isNotEmpty)
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: _textPrim),
                  onPressed: () => setState(() => _pageIndex = 4),
                ),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: _error, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${p.alertesNonLues.length + p.demandesEnAttente.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ]),
            IconButton(
              icon: const Icon(Icons.logout, color: _textSec),
              onPressed: () {
                p.seDeconnecter();
                // go_router redirige automatiquement via refreshListenable
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: _navItems.asMap().entries.map((e) {
                  final sel = _pageIndex == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _pageIndex = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? _orange.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? _orange.withValues(alpha: 0.4)
                                : _border),
                      ),
                      child: Row(children: [
                        Icon(
                          sel ? e.value.iconActive : e.value.icon,
                          color: sel ? _orange : _textSec,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(e.value.label,
                            style: TextStyle(
                              color: sel ? _orange : _textSec,
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: _buildPage(p),
      );
    });
  }

  Widget _buildDashboard(AppProvider p) {
    final stands = p.standsActifs;
    final totalEspeces = stands.fold(0.0, (s, st) => s + st.soldeEspeces);
    final totalSim = stands.fold(0.0, (s, st) => s + st.soldeTotalSim);

    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day);
    final opsJour = p.operations
        .where((o) => o.dateHeure.isAfter(debutJour))
        .toList();
    final ristournesJour = opsJour.fold(
        0.0, (s, o) => s + o.ristourneCalculee);

    return RefreshIndicator(
      color: _orange,
      onRefresh: p.rafraichir,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capital global
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B6CA8), Color(0xFF2196F3)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capital total (${stands.length} stands)',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt.format(totalEspeces + totalSim)} FCFA',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _miniStat('Espèces',
                        '${_fmt.format(totalEspeces)} F',
                        Icons.payments_outlined),
                    Container(width: 1, height: 36,
                        color: Colors.white.withValues(alpha: 0.3)),
                    _miniStat('SIM Mobile',
                        '${_fmt.format(totalSim)} F',
                        Icons.sim_card_outlined),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KPIs
            Row(children: [
              Expanded(child: _kpiCard('Ops du jour',
                  '${opsJour.length}', Icons.swap_horiz_rounded, _orange)),
              const SizedBox(width: 10),
              Expanded(child: _kpiCard('Ristournes',
                  '${_fmt.format(ristournesJour)} F',
                  Icons.percent_rounded, const Color(0xFF8B5CF6))),
              const SizedBox(width: 10),
              Expanded(child: _kpiCard('Alertes',
                  '${p.alertesNonLues.length}',
                  Icons.notifications_active_rounded,
                  p.alertesNonLues.isEmpty ? _success : _error)),
            ]),
            const SizedBox(height: 20),

            // Demandes en attente
            if (p.demandesEnAttente.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.pending_actions_rounded,
                      color: Color(0xFFFFB300)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p.demandesEnAttente.length} demande(s) en attente',
                      style: const TextStyle(
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _pageIndex = 4),
                    child: const Text('Voir',
                        style: TextStyle(color: Color(0xFFFFB300))),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Stands
            const Text('Stands',
                style: TextStyle(
                    color: _textPrim, fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...stands.take(5).map((s) {
              final niveauEsp = s.niveauAlerteEspeces(
                p.entrepriseActive?.seuilAlerteEspeces ?? 50000,
                p.entrepriseActive?.seuilCritiqueEspeces ?? 20000,
              );
              final couleur = niveauEsp == 'critique'
                  ? _error
                  : niveauEsp == 'alerte'
                      ? const Color(0xFFFFB300)
                      : _success;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(children: [
                  const Icon(Icons.store_rounded, color: _orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nom,
                            style: const TextStyle(
                                color: _textPrim,
                                fontWeight: FontWeight.bold)),
                        Text(s.lieu,
                            style: const TextStyle(
                                color: _textSec, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${_fmt.format(s.soldeEspeces)} F',
                        style: TextStyle(
                            color: couleur,
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('${_fmt.format(s.soldeTotalSim)} F SIM',
                        style: const TextStyle(
                            color: _textSec, fontSize: 11)),
                  ]),
                ]),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String val, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 3),
          Text(val,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _kpiCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: const TextStyle(color: _textSec, fontSize: 10)),
      ]),
    );
  }

  void _showDrawer(BuildContext ctx, AppProvider p) {
    showModalBottomSheet(
      context: ctx,
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
          ..._navItems.asMap().entries.map((e) => ListTile(
            leading: Icon(e.value.iconActive, color: _orange),
            title: Text(e.value.label,
                style: const TextStyle(color: _textPrim)),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _pageIndex = e.key);
            },
          )),
          const Divider(color: _border),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _error),
            title: const Text('Déconnexion',
                style: TextStyle(color: _error)),
            onTap: () {
              Navigator.pop(ctx);
              p.seDeconnecter();
              // go_router redirige automatiquement via refreshListenable
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData iconActive;
  final IconData icon;
  final String label;
  const _NavItem(this.iconActive, this.icon, this.label);
}
