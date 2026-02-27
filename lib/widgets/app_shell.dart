// lib/widgets/app_shell.dart
// Shell responsive pour tous les dashboards SikaFlow
// Mobile (<900px) : BottomNavigationBar ou Drawer
// Desktop (≥900px) : Sidebar fixe 260px + contenu scrollable à droite

import 'package:flutter/material.dart';

// ─── Types de navigation ───────────────────────────────────────────────────────
class NavItem {
  final IconData icon;
  final IconData iconSelected;
  final String label;

  const NavItem(this.icon, this.iconSelected, this.label);
}

// ─── Widget AppShell ──────────────────────────────────────────────────────────
class AppShell extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final String userNom;
  final String userRole;
  final String? entrepriseNom;
  final List<NavItem> navItems;
  final int indexCourant;
  final ValueChanged<int> onNavChanged;
  final Widget page;
  final List<Widget>? actionsAppBar;
  final VoidCallback? onDeconnexion;
  final Widget? floatingActionButton;
  final Color sidebarColor;
  final Color accentColor;
  final int badgeCount;

  const AppShell({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.userNom,
    required this.userRole,
    this.entrepriseNom,
    required this.navItems,
    required this.indexCourant,
    required this.onNavChanged,
    required this.page,
    this.actionsAppBar,
    this.onDeconnexion,
    this.floatingActionButton,
    this.sidebarColor = const Color(0xFF1A2130),
    this.accentColor = const Color(0xFFFF6B35),
    this.badgeCount = 0,
  });

  static const double _sidebarWidth = 260;
  static const double _breakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= _breakpoint;

    if (isDesktop) {
      return _DesktopLayout(shell: this);
    } else {
      return _MobileLayout(shell: this);
    }
  }
}

// ─── Layout Desktop ───────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final AppShell shell;
  const _DesktopLayout({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2530),
      body: Row(
        children: [
          // ── Sidebar fixe ──────────────────────────────────────────────────
          SizedBox(
            width: AppShell._sidebarWidth,
            child: _Sidebar(shell: shell),
          ),

          // ── Séparateur ────────────────────────────────────────────────────
          Container(width: 1, color: const Color(0xFF313D52)),

          // ── Contenu principal ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // AppBar desktop
                _DesktopHeader(shell: shell),
                // Contenu scrollable
                Expanded(
                  child: shell.page,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: shell.floatingActionButton,
    );
  }
}

// ─── Layout Mobile ────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final AppShell shell;
  const _MobileLayout({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2530),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2130),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shell.titre,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            if (shell.entrepriseNom != null)
              Text(shell.entrepriseNom!,
                  style: const TextStyle(
                      color: Color(0xFF8A9BB0), fontSize: 11)),
          ],
        ),
        actions: [
          if (shell.actionsAppBar != null) ...shell.actionsAppBar!,
          if (shell.badgeCount > 0)
            _BadgeIcon(
                count: shell.badgeCount,
                icon: Icons.notifications_rounded,
                color: shell.accentColor),
          const SizedBox(width: 8),
        ],
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: shell.sidebarColor,
        child: _Sidebar(shell: shell),
      ),
      body: shell.page,
      floatingActionButton: shell.floatingActionButton,
    );
  }
}

// ─── Sidebar réutilisable ─────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final AppShell shell;
  const _Sidebar({required this.shell});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppShell._breakpoint;

    return Container(
      color: shell.sidebarColor,
      child: Column(
        children: [
          // En-tête sidebar
          SafeArea(
            bottom: false,
            child: _buildHeader(context, isDesktop),
          ),

          const SizedBox(height: 8),

          // Items de navigation
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: shell.navItems.length,
              itemBuilder: (ctx, i) =>
                  _buildNavItem(context, shell.navItems[i], i, isDesktop),
            ),
          ),

          // Déconnexion
          if (shell.onDeconnexion != null) ...[
            const Divider(color: Color(0xFF313D52), height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SafeArea(
                top: false,
                child: _buildDeconnexionButton(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [shell.accentColor, shell.accentColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('S',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SikaFlow',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    if (shell.entrepriseNom != null)
                      Text(
                        shell.entrepriseNom!,
                        style: const TextStyle(
                            color: Color(0xFF8A9BB0), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: shell.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: shell.accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: shell.accentColor.withValues(alpha: 0.15),
                  child: Text(
                    shell.userNom.isNotEmpty
                        ? shell.userNom[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                        color: shell.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shell.userNom,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        shell.userRole,
                        style: const TextStyle(
                            color: Color(0xFF8A9BB0), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, NavItem item, int index, bool isDesktop) {
    final selected = index == shell.indexCourant;
    final color = shell.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isDesktop) Navigator.pop(context); // fermer le drawer mobile
            shell.onNavChanged(index);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: color.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.iconSelected : item.icon,
                  color: selected ? color : const Color(0xFF8A9BB0),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? color
                          : const Color(0xFF8A9BB0),
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeconnexionButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: shell.onDeconnexion,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4444).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFFF4444), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Déconnexion',
                  style: TextStyle(
                      color: Color(0xFFFF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header Desktop ───────────────────────────────────────────────────────────
class _DesktopHeader extends StatelessWidget {
  final AppShell shell;
  const _DesktopHeader({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2130),
        border: Border(
          bottom: BorderSide(color: Color(0xFF313D52), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Titre de la page courante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shell.navItems.isNotEmpty &&
                          shell.indexCourant < shell.navItems.length
                      ? shell.navItems[shell.indexCourant].label
                      : shell.titre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                if (shell.sousTitre.isNotEmpty)
                  Text(shell.sousTitre,
                      style: const TextStyle(
                          color: Color(0xFF8A9BB0), fontSize: 11)),
              ],
            ),
          ),

          // Actions
          if (shell.actionsAppBar != null) ...shell.actionsAppBar!,

          // Badge notifications
          if (shell.badgeCount > 0)
            _BadgeIcon(
                count: shell.badgeCount,
                icon: Icons.notifications_rounded,
                color: shell.accentColor),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Badge icon ───────────────────────────────────────────────────────────────
class _BadgeIcon extends StatelessWidget {
  final int count;
  final IconData icon;
  final Color color;

  const _BadgeIcon(
      {required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: const Color(0xFF8A9BB0), size: 22),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              constraints:
                  const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
