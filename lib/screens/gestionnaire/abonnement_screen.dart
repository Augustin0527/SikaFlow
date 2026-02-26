import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/abonnement_model.dart';

const _bg      = Color(0xFF1E2530);
const _surface = Color(0xFF252D3A);
const _border  = Color(0xFF313D52);
const _orange  = Color(0xFFFF6B35);
const _success = Color(0xFF00C896);
const _textP   = Color(0xFFF0F4F8);
const _textS   = Color(0xFF8A9BB0);

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  PeriodeAbonnement _periode = PeriodeAbonnement.mensuel;
  final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final ent = p.entrepriseActive;
      final nbStands = p.standsActifs.length;
      final abonnements = p.abonnements;
      final planRecommande = PlanStands.pourNombreDeStands(nbStands == 0 ? 1 : nbStands);

      // Abonnement actif en cours
      final AbonnementModel? aboCurrent = abonnements
          .where((a) => a.estActif)
          .fold<AbonnementModel?>(null, (prev, a) =>
              prev == null || a.dateFin.isAfter(prev.dateFin) ? a : prev);

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ───────────────────────────────────────────────────
              const Text('Abonnement',
                  style: TextStyle(color: _textP, fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Gérez votre abonnement SikaFlow',
                  style: const TextStyle(color: _textS, fontSize: 13)),
              const SizedBox(height: 20),

              // ── Statut actuel ─────────────────────────────────────────────
              _buildStatutActuel(aboCurrent, nbStands, ent?.dateFinEssai),
              const SizedBox(height: 24),

              // ── Nombre de stands actifs ───────────────────────────────────
              _buildInfoStands(nbStands, planRecommande),
              const SizedBox(height: 24),

              // ── Toggle mensuel / annuel ───────────────────────────────────
              _buildTogglePeriode(),
              const SizedBox(height: 20),

              // ── Grille des plans ──────────────────────────────────────────
              const Text('Choisissez votre plan',
                  style: TextStyle(color: _textP, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...PlanStands.tous.map((plan) =>
                  _buildPlanCard(plan, planRecommande, aboCurrent)),
              const SizedBox(height: 24),

              // ── Historique ────────────────────────────────────────────────
              if (abonnements.isNotEmpty) ...[
                const Text('Historique',
                    style: TextStyle(color: _textP, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...abonnements.map((a) => _buildHistoriqueItem(a)),
              ],
            ],
          ),
        ),
      );
    });
  }

  // ── Statut actuel ──────────────────────────────────────────────────────────
  Widget _buildStatutActuel(AbonnementModel? abo, int nbStands, DateTime? finEssai) {
    final bool enEssai = abo == null || abo.estEssai;
    final joursRestants = enEssai && finEssai != null
        ? finEssai.difference(DateTime.now()).inDays.clamp(0, 999)
        : (abo?.joursRestants ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enEssai
              ? [const Color(0xFF2196F3), const Color(0xFF0D47A1)]
              : [_orange, const Color(0xFFE55A2B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: (enEssai ? const Color(0xFF2196F3) : _orange)
              .withValues(alpha: 0.3),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(enEssai ? Icons.timer_outlined : Icons.workspace_premium_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(enEssai ? 'Période d\'essai' : 'Plan actif',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                Text(
                  enEssai
                      ? 'Essai gratuit (30 jours)'
                      : '${abo!.plan.label} – ${abo.periode.label}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  joursRestants > 0
                      ? '$joursRestants jour${joursRestants > 1 ? "s" : ""} restant${joursRestants > 1 ? "s" : ""}'
                      : 'Expiré',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (!enEssai && abo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expire le ${DateFormat('dd/MM/yyyy').format(abo.dateFin)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Text('$nbStands',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('stands', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Info stands ────────────────────────────────────────────────────────────
  Widget _buildInfoStands(int nbStands, PlanStands recommande) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(recommande.couleurHex).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Color(recommande.couleurHex).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storefront_rounded,
                color: Color(recommande.couleurHex), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous avez $nbStands stand${nbStands > 1 ? "s" : ""} actif${nbStands > 1 ? "s" : ""}',
                  style: const TextStyle(color: _textP, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('Plan recommandé : ${recommande.label}',
                  style: TextStyle(color: Color(recommande.couleurHex), fontSize: 13)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color(recommande.couleurHex).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(recommande.maxStandsLabel,
                style: TextStyle(color: Color(recommande.couleurHex),
                    fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Toggle période ─────────────────────────────────────────────────────────
  Widget _buildTogglePeriode() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: PeriodeAbonnement.values.map((p) {
          final selected = _periode == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _periode = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.label,
                        style: TextStyle(
                          color: selected ? Colors.white : _textS,
                          fontWeight: FontWeight.bold, fontSize: 14,
                        )),
                    if (p == PeriodeAbonnement.annuel) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.25)
                              : _success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-20%',
                            style: TextStyle(
                              color: selected ? Colors.white : _success,
                              fontSize: 10, fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Carte d'un plan ────────────────────────────────────────────────────────
  Widget _buildPlanCard(PlanStands plan, PlanStands recommande,
      AbonnementModel? aboCurrent) {
    final isRecommande = plan.code == recommande.code;
    final isCurrent = aboCurrent?.plan.code == plan.code;
    final color = Color(plan.couleurHex);
    final prixMensuel = plan.prixMensuelAvecPeriode(_periode);
    final total = plan.totalPeriode(_periode);
    final economie = plan.economieAnnuelle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommande ? color : (isCurrent ? _orange : _border),
          width: isRecommande || isCurrent ? 2 : 1,
        ),
        boxShadow: isRecommande ? [BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 12, offset: const Offset(0, 4),
        )] : null,
      ),
      child: Column(
        children: [
          // Badge recommandé
          if (isRecommande)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text('Recommandé pour vous',
                      style: TextStyle(color: color,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storefront_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(plan.label,
                                style: const TextStyle(color: _textP,
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Actuel',
                                    style: TextStyle(color: _orange,
                                        fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ]),
                          Text(plan.description,
                              style: const TextStyle(color: _textS, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(text: TextSpan(children: [
                          TextSpan(
                            text: _fmt.format(prixMensuel),
                            style: TextStyle(color: color,
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' F',
                              style: TextStyle(color: _textS, fontSize: 13)),
                        ])),
                        const Text('/mois', style: TextStyle(color: _textS, fontSize: 11)),
                        if (_periode == PeriodeAbonnement.annuel) ...[
                          const SizedBox(height: 2),
                          Text('${_fmt.format(total)} F/an',
                              style: const TextStyle(color: _textS, fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),

                if (_periode == PeriodeAbonnement.annuel && economie > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _success.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.savings_rounded,
                          color: _success, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Économie de ${_fmt.format(economie)} FCFA/an par rapport au mensuel',
                        style: const TextStyle(color: _success, fontSize: 11),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 14),

                // Plage de stands
                _infoRow(
                  Icons.storefront_rounded,
                  color,
                  plan.maxStands == -1
                      ? '${plan.minStands} stands et plus'
                      : plan.minStands == plan.maxStands
                          ? '${plan.minStands} stand'
                          : '${plan.minStands} à ${plan.maxStands} stands',
                ),
                const SizedBox(height: 6),
                _infoRow(Icons.people_rounded, color,
                    'Agents et membres illimités'),
                const SizedBox(height: 6),
                _infoRow(Icons.bar_chart_rounded, color,
                    'Rapports et statistiques complets'),

                const SizedBox(height: 16),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent
                        ? null
                        : () => _showConfirmationSouscription(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent
                          ? _border
                          : (isRecommande ? color : _surface),
                      foregroundColor: isCurrent ? _textS : Colors.white,
                      side: isCurrent
                          ? null
                          : BorderSide(color: color, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isCurrent
                          ? 'Plan actuel'
                          : isRecommande
                              ? 'Choisir ${plan.label}'
                              : 'Souscrire',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String text) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: _textS, fontSize: 12)),
    ]);
  }

  // ── Historique ─────────────────────────────────────────────────────────────
  Widget _buildHistoriqueItem(AbonnementModel abo) {
    final color = Color(abo.plan.couleurHex);
    final isActif = abo.estActif;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${abo.plan.label} – ${abo.periode.label}',
                    style: const TextStyle(color: _textP,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(abo.dateDebut)} → '
                  '${DateFormat('dd/MM/yyyy').format(abo.dateFin)}',
                  style: const TextStyle(color: _textS, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActif
                      ? _success.withValues(alpha: 0.15)
                      : _textS.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActif ? 'Actif' : abo.statut.label,
                  style: TextStyle(
                    color: isActif ? _success : _textS,
                    fontSize: 10, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt.format(abo.montantPaye.toInt())} F',
                style: const TextStyle(color: _textP,
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dialogue confirmation ──────────────────────────────────────────────────
  void _showConfirmationSouscription(PlanStands plan) {
    final total = plan.totalPeriode(_periode);
    final fmt = _fmt;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.workspace_premium_rounded,
              color: Color(plan.couleurHex), size: 22),
          const SizedBox(width: 8),
          Text('Plan ${plan.label}',
              style: const TextStyle(color: _textP,
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.description,
                style: const TextStyle(color: _textS, fontSize: 13)),
            const SizedBox(height: 16),
            _dialogRow('Période', _periode.label),
            _dialogRow('Stands inclus', plan.maxStandsLabel),
            _dialogRow('Prix/mois',
                '${fmt.format(plan.prixMensuelAvecPeriode(_periode))} FCFA'),
            if (_periode == PeriodeAbonnement.annuel)
              _dialogRow('Total annuel', '${fmt.format(total)} FCFA'),
            _dialogRow('Économie',
                _periode == PeriodeAbonnement.annuel
                    ? '${fmt.format(plan.economieAnnuelle())} FCFA/an'
                    : 'Optez pour l\'annuel pour économiser 20%'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Le paiement sera traité via FedaPay. '
                'Vous pouvez payer par mobile money (MTN, Moov) '
                'ou par carte.',
                style: TextStyle(color: _textS, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: _textS)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lancerPaiement(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(plan.couleurHex),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Payer ${fmt.format(total)} FCFA'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textS, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: _textP,
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _lancerPaiement(PlanStands plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirection vers FedaPay pour le plan ${plan.label}…',
        ),
        backgroundColor: Color(plan.couleurHex),
        duration: const Duration(seconds: 3),
      ),
    );
    // TODO: intégrer FedaPay avec le vrai service de paiement
  }
}
