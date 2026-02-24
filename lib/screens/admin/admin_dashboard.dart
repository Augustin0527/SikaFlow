import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'admin_entreprise_detail.dart';
import 'admin_abonnement_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerStats());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final stats = await _fs.getStatsGlobales();
    if (mounted) setState(() { _stats = stats; _chargement = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('SikaFlow Control Center', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _chargement = true); _chargerStats(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.business, size: 18), text: 'Entreprises'),
            Tab(icon: Icon(Icons.payment, size: 18), text: 'Abonnements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildEntreprises(),
          _buildAbonnements(),
        ],
      ),
    );
  }

  // ── Onglet Dashboard ────────────────────────────────────────────────────
  Widget _buildDashboard() {
    if (_chargement) return const Center(child: CircularProgressIndicator(color: Colors.orange));
    final fmt = NumberFormat('#,###', 'fr_FR');
    return RefreshIndicator(
      onRefresh: _chargerStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre
          const Text('Vue d\'ensemble', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Grille stats
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard('Entreprises', '${_stats['total_entreprises'] ?? 0}', Icons.business, Colors.blue),
              _statCard('Actives', '${_stats['actives'] ?? 0}', Icons.check_circle, Colors.green),
              _statCard('En essai', '${_stats['essai'] ?? 0}', Icons.hourglass_top, Colors.orange),
              _statCard('Suspendues', '${_stats['suspendues'] ?? 0}', Icons.block, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard('Utilisateurs', '${_stats['total_utilisateurs'] ?? 0}', Icons.people, Colors.purple),
              _statCard('Abonnements', '${_stats['total_abonnements'] ?? 0}', Icons.receipt_long, Colors.teal),
              _statCard('Revenus FCFA', fmt.format(_stats['revenus_total'] ?? 0), Icons.account_balance_wallet, Colors.amber),
              _statCard('Expirées', '${_stats['expirees'] ?? 0}', Icons.warning, Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 24),

          // Accès rapides
          const Text('Actions rapides', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _actionRapide(
            icon: Icons.add_business,
            titre: 'Activer abonnement manuel',
            sousTitre: 'Accorder 6 mois à une entreprise',
            couleur: Colors.green,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(height: 8),
          _actionRapide(
            icon: Icons.block,
            titre: 'Suspendre une entreprise',
            sousTitre: 'Bloquer l\'accès temporairement',
            couleur: Colors.red,
            onTap: () => _tabController.animateTo(1),
          ),
        ]),
      ),
    );
  }

  // ── Onglet Entreprises ──────────────────────────────────────────────────
  Widget _buildEntreprises() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.allEntreprisesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.business_center, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Aucune entreprise inscrite', style: TextStyle(color: Colors.white54)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            return _entrepriseCard(data, id);
          },
        );
      },
    );
  }

  // ── Onglet Abonnements ──────────────────────────────────────────────────
  Widget _buildAbonnements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('entreprises').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final entreprises = snap.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Bouton ajout manuel
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Accorder abonnement manuel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminAbonnementScreen(entreprises: entreprises),
                )),
              ),
            ),

            // Liste abonnements récents
            const Text('Abonnements enregistrés', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fs.getAllAbonnements(),
              builder: (context, snapAbo) {
                if (!snapAbo.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                final abos = snapAbo.data!;
                if (abos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Aucun abonnement enregistré', style: TextStyle(color: Colors.white54))),
                  );
                }
                return Column(
                  children: abos.map((abo) => _abonnementCard(abo, entreprises)).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ── Widgets helpers ─────────────────────────────────────────────────────
  Widget _statCard(String titre, String valeur, IconData icon, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: couleur, size: 22),
        const Spacer(),
        Text(valeur, style: TextStyle(color: couleur, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(titre, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _actionRapide({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: couleur, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(sousTitre, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: couleur),
        ]),
      ),
    );
  }

  Widget _entrepriseCard(Map<String, dynamic> data, String id) {
    final statut = data['statut'] ?? 'essai';
    final expiration = (data['date_expiration_abonnement'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final expired = expiration != null && expiration.isBefore(now);

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'actif': statutColor = expired ? Colors.deepOrange : Colors.green; statutLabel = expired ? 'Expiré' : 'Actif'; break;
      case 'suspendu': statutColor = Colors.red; statutLabel = 'Suspendu'; break;
      default: statutColor = Colors.orange; statutLabel = 'Essai';
    }

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          child: Text(
            (data['nom'] ?? '?')[0].toUpperCase(),
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(data['nom'] ?? 'Sans nom', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (expiration != null)
            Text('Expire: ${DateFormat('dd/MM/yyyy').format(expiration)}',
                style: TextStyle(color: expired ? Colors.deepOrange : Colors.white54, fontSize: 12)),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statutColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statutLabel, style: TextStyle(color: statutColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AdminEntrepriseDetail(entrepriseId: id, data: data),
            )),
          ),
        ]),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdminEntrepriseDetail(entrepriseId: id, data: data),
        )),
      ),
    );
  }

  Widget _abonnementCard(Map<String, dynamic> abo, List<QueryDocumentSnapshot> entreprises) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final entrepriseId = abo['entreprise_id'] ?? '';
    final entrepriseData = entreprises
        .where((e) => e.id == entrepriseId)
        .map((e) => e.data() as Map<String, dynamic>)
        .firstOrNull;
    final nomEntreprise = entrepriseData?['nom'] ?? entrepriseId;
    final date = (abo['created_at'] as Timestamp?)?.toDate();
    final mode = abo['mode_paiement'] ?? 'manuel';

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mode == 'fedapay' ? Colors.teal.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
          child: Icon(
            mode == 'fedapay' ? Icons.payment : Icons.person,
            color: mode == 'fedapay' ? Colors.teal : Colors.green,
            size: 18,
          ),
        ),
        title: Text(nomEntreprise, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${fmt.format(abo['montant'] ?? 0)} FCFA • ${abo['duree_mois'] ?? 6} mois • ${mode.toUpperCase()}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: date != null
            ? Text(DateFormat('dd/MM/yy').format(date), style: const TextStyle(color: Colors.white38, fontSize: 11))
            : null,
      ),
    );
  }
}
