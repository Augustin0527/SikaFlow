import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/operation_model.dart';
import '../../theme/app_theme.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _error    = Color(0xFFFF4444);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  String _periode = 'semaine';
  final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final now = DateTime.now();

      // Filtrer selon la période
      late DateTime debut;
      switch (_periode) {
        case 'jour':
          debut = DateTime(now.year, now.month, now.day);
          break;
        case 'semaine':
          debut = now.subtract(const Duration(days: 7));
          break;
        case 'mois':
          debut = DateTime(now.year, now.month, 1);
          break;
        default:
          debut = now.subtract(const Duration(days: 7));
      }

      final ops = p.operations
          .where((o) => o.dateHeure.isAfter(debut))
          .toList();

      final totalVolume     = ops.fold(0.0, (s, o) => s + o.montant);
      final totalRistournes = ops.fold(0.0, (s, o) => s + o.ristourneCalculee);
      final nbDepots        = ops.where((o) => o.typeOperation == 'depot').length;
      final nbRetraits      = ops.where((o) => o.typeOperation == 'retrait').length;
      final nbCredits       = ops.where((o) => o.typeOperation == 'credit_forfait').length;

      // Par opérateur
      final Map<String, double> parOperateur = {};
      for (final op in ops) {
        parOperateur[op.operateur] =
            (parOperateur[op.operateur] ?? 0) + op.montant;
      }

      return Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Rapports',
                        style: TextStyle(
                            color: _textPrim,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  // Sélecteur de période
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(children: [
                      _periodeBtn('Jour', 'jour'),
                      _periodeBtn('Semaine', 'semaine'),
                      _periodeBtn('Mois', 'mois'),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPIs
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _kpiCard('Volume total',
                      '${_fmt.format(totalVolume)} F',
                      Icons.account_balance_wallet_rounded, _orange),
                  _kpiCard('Ristournes',
                      '${_fmt.format(totalRistournes)} F',
                      Icons.percent_rounded, const Color(0xFF8B5CF6)),
                  _kpiCard('Dépôts',
                      '$nbDepots opérations',
                      Icons.arrow_downward_rounded, _success),
                  _kpiCard('Retraits',
                      '$nbRetraits opérations',
                      Icons.arrow_upward_rounded, _error),
                ],
              ),
              const SizedBox(height: 20),

              // Par opérateur
              const Text('Volume par opérateur',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (parOperateur.isEmpty)
                _buildEmpty('Aucune opération sur la période')
              else
                ...parOperateur.entries.map((e) {
                  final pct = totalVolume > 0
                      ? e.value / totalVolume
                      : 0.0;
                  return _buildOperateurRow(e.key, e.value, pct);
                }),

              const SizedBox(height: 20),

              // Stats par type
              const Text('Répartition par type',
                  style: TextStyle(
                      color: _textPrim,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(children: [
                  _typeRow('Dépôts', nbDepots, ops.length, _success),
                  const SizedBox(height: 10),
                  _typeRow('Retraits', nbRetraits, ops.length, _error),
                  const SizedBox(height: 10),
                  _typeRow('Crédits/Forfaits', nbCredits, ops.length,
                      const Color(0xFF8B5CF6)),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _periodeBtn(String label, String val) {
    final sel = _periode == val;
    return GestureDetector(
      onTap: () => setState(() => _periode = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _orange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? Colors.white : _textSec,
              fontSize: 12,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _kpiCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(val,
            style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: const TextStyle(color: _textSec, fontSize: 11)),
      ]),
    );
  }

  Widget _buildOperateurRow(String operateur, double montant, double pct) {
    final colors = {
      'MTN': const Color(0xFFFFCC00),
      'MOOV': const Color(0xFF0066CC),
      'CELTIIS': const Color(0xFFCC0000),
    };
    final color = colors[operateur] ?? _orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(operateur,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Text('${_fmt.format(montant)} FCFA',
              style: const TextStyle(
                  color: _textPrim, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text('${(pct * 100).toStringAsFixed(1)}% du volume total',
            style: const TextStyle(color: _textSec, fontSize: 11)),
      ]),
    );
  }

  Widget _typeRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label,
            style: const TextStyle(color: _textPrim, fontSize: 13)),
      ),
      Text('$count',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(width: 8),
      Text('(${(pct * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(color: _textSec, fontSize: 11)),
    ]);
  }

  Widget _buildEmpty(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(msg,
            style: const TextStyle(color: _textSec, fontSize: 13)),
      ),
    );
  }
}
