import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/abonnement_model.dart';
import '../../services/fedapay_service.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  PlanAbonnement? _planSelectionne;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().chargerAbonnements();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Abonnement'),
        backgroundColor: AppTheme.primaryDark,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentOrange,
          labelColor: AppTheme.accentOrange,
          unselectedLabelColor: AppTheme.textHint,
          tabs: const [
            Tab(text: 'Nos Plans'),
            Tab(text: 'Mon Abonnement'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOngletPlans(),
          _buildOngletMonAbonnement(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ONGLET 1 — CHOISIR UN PLAN
  // ═══════════════════════════════════════════════════════
  Widget _buildOngletPlans() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final abonnementActif = provider.abonnementActif;
        final planActuel = abonnementActif?.plan ?? PlanAbonnement.essai;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bannière statut actuel ──────────────────────────────────
              _buildBanniereStatut(abonnementActif),
              const SizedBox(height: 20),

              const Text(
                'Choisissez votre plan',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Payez en MTN MoMo, Moov Money, Celtiis ou carte bancaire',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ── Cartes plans ────────────────────────────────────────────
              ...PlanAbonnement.values
                  .where((p) => p != PlanAbonnement.essai)
                  .map((plan) => _buildCartePlan(
                    plan: plan,
                    estActuel: plan == planActuel,
                    estSelectionne: _planSelectionne == plan,
                    onTap: () => setState(() => _planSelectionne = plan),
                  )),

              const SizedBox(height: 24),

              // ── Bouton payer ────────────────────────────────────────────
              if (_planSelectionne != null) ...[
                _buildBoutonPayer(provider),
                const SizedBox(height: 16),
              ],

              // ── Sécurité FedaPay ────────────────────────────────────────
              _buildBanniereSecurite(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanniereStatut(AbonnementModel? abonnement) {
    if (abonnement == null) return const SizedBox.shrink();

    final joursRestants = abonnement.joursRestants;
    final estEssai = abonnement.plan == PlanAbonnement.essai;
    final couleur = abonnement.expireBientot ? AppTheme.warning : AppTheme.success;
    final icone = abonnement.expireBientot ? Icons.warning_amber_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estEssai
                      ? 'Période d\'essai'
                      : 'Plan ${abonnement.plan.nom} actif',
                  style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  joursRestants > 0
                      ? '$joursRestants jour(s) restant(s)'
                      : 'Abonnement expiré',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (joursRestants > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                abonnement.plan.prixFormate,
                style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartePlan({
    required PlanAbonnement plan,
    required bool estActuel,
    required bool estSelectionne,
    required VoidCallback onTap,
  }) {
    final couleur = Color(plan.couleur);
    final estPopulaire = plan == PlanAbonnement.business;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: estSelectionne
              ? couleur.withValues(alpha: 0.12)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: estSelectionne
                ? couleur
                : estActuel
                    ? couleur.withValues(alpha: 0.4)
                    : AppTheme.divider,
            width: estSelectionne ? 2 : 1,
          ),
          boxShadow: estSelectionne
              ? [BoxShadow(color: couleur.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête plan ──
                  Row(
                    children: [
                      Text(plan.icone, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.nom, style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(plan.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.prix == 0 ? 'Gratuit' : '${_formatPrix(plan.prix)} FCFA',
                            style: TextStyle(color: couleur, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (plan.prix > 0)
                            const Text('/mois', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 10),
                  // ── Features ──
                  _buildFeature(couleur, Icons.group_rounded,
                      plan.agentsMax == -1 ? 'Agents illimités' : '${plan.agentsMax} agents maximum'),
                  _buildFeature(couleur, Icons.bar_chart_rounded, 'Rapports et statistiques'),
                  _buildFeature(couleur, Icons.payments_rounded, 'Gestion des retraits'),
                  if (plan == PlanAbonnement.business || plan == PlanAbonnement.premium)
                    _buildFeature(couleur, Icons.star_rounded, 'Ristournes automatiques'),
                  if (plan == PlanAbonnement.premium) ...[
                    _buildFeature(couleur, Icons.support_agent_rounded, 'Support prioritaire'),
                    _buildFeature(couleur, Icons.cloud_sync_rounded, 'Export données illimité'),
                  ],
                ],
              ),
            ),
            // Badge populaire
            if (estPopulaire)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('⭐ Populaire', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            // Badge actuel
            if (estActuel && !estPopulaire)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: couleur.withValues(alpha: 0.4)),
                  ),
                  child: Text('Plan actuel', style: TextStyle(color: couleur, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            // Sélection
            if (estSelectionne)
              Positioned(
                bottom: 14,
                right: 14,
                child: Icon(Icons.check_circle_rounded, color: couleur, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(Color couleur, IconData icon, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 14),
          const SizedBox(width: 8),
          Text(texte, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBoutonPayer(AppProvider provider) {
    final plan = _planSelectionne!;
    final couleur = Color(plan.couleur);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [couleur, couleur.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _enCours ? null : () => _lancerPaiement(provider, plan),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _enCours
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Préparation du paiement...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Payer ${_formatPrix(plan.prix)} FCFA — ${plan.nom}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBanniereSecurite() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppTheme.accentOrange, size: 16),
              SizedBox(width: 8),
              Text('Paiement 100% sécurisé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badgePaiement('assets/logos/mtn_momo.png', 'MTN MoMo'),
              _badgePaiement('assets/logos/moov_money.png', 'Moov Money'),
              _badgePaiement('assets/logos/celtiis_cash.png', 'Celtiis'),
              _badgeTexte(Icons.credit_card_rounded, 'Carte bancaire'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by FedaPay • Transactions cryptées SSL',
            style: TextStyle(color: AppTheme.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _badgePaiement(String assetPath, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 16, color: AppTheme.textHint)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _badgeTexte(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textHint),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ONGLET 2 — MON ABONNEMENT
  // ═══════════════════════════════════════════════════════
  Widget _buildOngletMonAbonnement() {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final abonnement = provider.abonnementActif;
        final historique = provider.historiqueAbonnements;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Abonnement actif ──────────────────────────────────────
              if (abonnement != null)
                _buildCarteAbonnementActif(abonnement)
              else
                _buildCarteAucunAbonnement(),

              const SizedBox(height: 24),

              // ── Historique ────────────────────────────────────────────
              const Text(
                'Historique des paiements',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (historique.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Aucun paiement effectué', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                  ),
                )
              else
                ...historique.map((a) => _buildLigneHistorique(a)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarteAbonnementActif(AbonnementModel abonnement) {
    final couleur = Color(abonnement.plan.couleur);
    final joursRestants = abonnement.joursRestants;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur.withValues(alpha: 0.2), couleur.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(abonnement.plan.icone, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan ${abonnement.plan.nom}',
                      style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      abonnement.estActif ? 'Actif' : 'Expiré',
                      style: TextStyle(color: abonnement.estActif ? AppTheme.success : AppTheme.error, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: abonnement.estActif
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  abonnement.estActif ? '✓ Actif' : '✗ Expiré',
                  style: TextStyle(
                    color: abonnement.estActif ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),

          // Barre progression jours restants
          if (joursRestants >= 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jours restants', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  '$joursRestants / ${abonnement.plan.dureeJours} jours',
                  style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: joursRestants / abonnement.plan.dureeJours,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation(couleur),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Infos détail
          _infoLigne(Icons.calendar_today_rounded, 'Début', _formatDate(abonnement.dateDebut)),
          _infoLigne(Icons.event_rounded, 'Expiration', _formatDate(abonnement.dateExpiration)),
          _infoLigne(Icons.payments_rounded, 'Montant payé', '${_formatPrix(abonnement.montantPaye.toInt())} FCFA'),
          if (abonnement.fedapayReference != null)
            _infoLigne(Icons.receipt_rounded, 'Référence', abonnement.fedapayReference!),
        ],
      ),
    );
  }

  Widget _buildCarteAucunAbonnement() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.subscriptions_outlined, color: AppTheme.textHint, size: 48),
          const SizedBox(height: 12),
          const Text('Aucun abonnement actif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Choisissez un plan pour continuer à utiliser SikaFlow', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _tabCtrl.animateTo(0),
            child: const Text('Voir les plans'),
          ),
        ],
      ),
    );
  }

  Widget _buildLigneHistorique(AbonnementModel abonnement) {
    final couleur = Color(abonnement.plan.couleur);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(abonnement.plan.icone, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan ${abonnement.plan.nom}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(_formatDate(abonnement.dateCreation), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_formatPrix(abonnement.montantPaye.toInt())} FCFA', style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: abonnement.estActif ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  abonnement.statut.label,
                  style: TextStyle(
                    color: abonnement.estActif ? AppTheme.success : AppTheme.textHint,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLigne(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textHint),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
          Expanded(
            child: Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LANCER LE PAIEMENT
  // ═══════════════════════════════════════════════════════
  Future<void> _lancerPaiement(AppProvider provider, PlanAbonnement plan) async {
    final user = provider.utilisateurConnecte!;
    final entreprise = provider.entrepriseActive;
    if (entreprise == null) return;

    setState(() => _enCours = true);

    // Créer la transaction FedaPay
    final resultat = await FedaPayService.creerTransaction(
      plan: plan,
      entrepriseId: entreprise.id,
      gestionnaireId: user.id,
      nomGestionnaire: user.nomComplet,
      emailGestionnaire: user.email ?? '${user.id}@sikaflow.app',
      nomEntreprise: entreprise.nom,
    );

    setState(() => _enCours = false);

    if (!mounted) return;

    if (!resultat.succes) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : ${resultat.erreur}'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Ouvrir le WebView de paiement FedaPay
    final paymentResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FedaPayCheckoutScreen(
          urlPaiement: resultat.urlPaiement!,
          transactionId: resultat.transactionId!,
          plan: plan,
        ),
      ),
    );

    if (!mounted) return;

    if (paymentResult == true) {
      // Paiement approuvé → enregistrer dans Firestore
      await provider.enregistrerAbonnement(
        plan: plan,
        transactionId: resultat.transactionId!,
        reference: resultat.reference ?? '',
      );
      if (!mounted) return;
      _tabCtrl.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 Abonnement activé avec succès !'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ));
    } else if (paymentResult == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Paiement annulé ou échoué.'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatPrix(int prix) {
    final s = prix.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉCRAN WEBVIEW — CHECKOUT FEDAPAY
// ═══════════════════════════════════════════════════════════════════════════
class FedaPayCheckoutScreen extends StatefulWidget {
  final String urlPaiement;
  final String transactionId;
  final PlanAbonnement plan;

  const FedaPayCheckoutScreen({
    super.key,
    required this.urlPaiement,
    required this.transactionId,
    required this.plan,
  });

  @override
  State<FedaPayCheckoutScreen> createState() => _FedaPayCheckoutScreenState();
}

class _FedaPayCheckoutScreenState extends State<FedaPayCheckoutScreen> {
  late final WebViewController _webCtrl;
  bool _loading = true;
  Timer? _pollingTimer;
  int _tentatives = 0;
  static const int _maxTentatives = 60; // 5 minutes max

  @override
  void initState() {
    super.initState();
    _initWebView();
    _demarrerPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1A2E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            // Détecter redirection callback (succès ou annulation)
            final url = req.url;
            if (url.contains('payment-callback') || url.contains('sikaflow-c8869.web.app')) {
              if (url.contains('approved') || url.contains('success')) {
                _pollingTimer?.cancel();
                Navigator.pop(context, true);
              } else if (url.contains('canceled') || url.contains('declined')) {
                _pollingTimer?.cancel();
                Navigator.pop(context, false);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.urlPaiement));
  }

  void _demarrerPolling() {
    // Vérifier le statut toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      _tentatives++;
      if (_tentatives > _maxTentatives) {
        _pollingTimer?.cancel();
        return;
      }

      final statut = await FedaPayService.verifierStatutTransaction(widget.transactionId);
      debugPrint('FedaPay polling statut: $statut (tentative $_tentatives)');

      if (!mounted) return;

      if (statut == 'approved') {
        _pollingTimer?.cancel();
        Navigator.pop(context, true);
      } else if (statut == 'canceled' || statut == 'declined') {
        _pollingTimer?.cancel();
        Navigator.pop(context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppTheme.success, size: 16),
            const SizedBox(width: 8),
            Text(
              'Paiement — ${widget.plan.nom}',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _pollingTimer?.cancel();
            Navigator.pop(context, false);
          },
        ),
        actions: [
          // Indicateur montant
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(widget.plan.couleur).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.plan.prixFormate,
              style: TextStyle(color: Color(widget.plan.couleur), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webCtrl),
          if (_loading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentOrange),
                  SizedBox(height: 16),
                  Text('Chargement du formulaire de paiement...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
      // Barre de progression polling
      bottomNavigationBar: Container(
        color: AppTheme.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(color: AppTheme.success, strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Text('En attente du paiement...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.shield_rounded, color: AppTheme.success, size: 14),
            const SizedBox(width: 4),
            const Text('FedaPay', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
