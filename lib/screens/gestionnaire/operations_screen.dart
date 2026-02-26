import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/operation_model.dart';


const _bg        = Color(0xFF1E2530);
const _surface   = Color(0xFF252D3A);
const _border    = Color(0xFF313D52);
const _orange    = Color(0xFFFF6B35);
const _success   = Color(0xFF00C896);
const _error     = Color(0xFFFF4444);
const _textPrim  = Color(0xFFF0F4F8);
const _textSec   = Color(0xFF8A9BB0);

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  String _filtreType = 'tous';
  String _filtreOp   = 'tous';
  final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      var ops = p.operations.toList()
        ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

      if (_filtreType != 'tous') {
        ops = ops.where((o) => o.typeOperation == _filtreType).toList();
      }
      if (_filtreOp != 'tous') {
        ops = ops.where((o) => o.operateur == _filtreOp).toList();
      }

      return Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Filtres
            Container(
              color: _surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Opérations',
                      style: TextStyle(
                          color: _textPrim,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _filterChip('Tous', 'tous', _filtreType,
                          (v) => setState(() => _filtreType = v)),
                      _filterChip('Dépôt', 'depot', _filtreType,
                          (v) => setState(() => _filtreType = v)),
                      _filterChip('Retrait', 'retrait', _filtreType,
                          (v) => setState(() => _filtreType = v)),
                      _filterChip('Crédit', 'credit_forfait', _filtreType,
                          (v) => setState(() => _filtreType = v)),
                      const SizedBox(width: 12),
                      _filterChip('MTN', 'MTN', _filtreOp,
                          (v) => setState(() => _filtreOp = v)),
                      _filterChip('Moov', 'MOOV', _filtreOp,
                          (v) => setState(() => _filtreOp = v)),
                      _filterChip('Celtiis', 'CELTIIS', _filtreOp,
                          (v) => setState(() => _filtreOp = v)),
                    ]),
                  ),
                ],
              ),
            ),
            // Liste
            Expanded(
              child: ops.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ops.length,
                      itemBuilder: (_, i) => _buildOpCard(ops[i]),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterChip(String label, String val, String current,
      ValueChanged<String> onTap) {
    final sel = current == val;
    return GestureDetector(
      onTap: () => onTap(val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _orange : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _orange : _border),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : _textSec,
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildOpCard(OperationModel op) {
    final colors = {
      'depot': _success,
      'retrait': _error,
      'credit_forfait': const Color(0xFF8B5CF6),
    };
    final icons = {
      'depot': Icons.arrow_downward_rounded,
      'retrait': Icons.arrow_upward_rounded,
      'credit_forfait': Icons.phone_android_rounded,
    };
    final color = colors[op.typeOperation] ?? _textSec;
    final icon  = icons[op.typeOperation] ?? Icons.swap_horiz_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${op.operateur} — ${op.typeOperation.replaceAll('_', ' ')}',

                style: const TextStyle(
                    color: _textPrim,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text(op.standNom ?? '',
                style: const TextStyle(color: _textSec, fontSize: 11)),
            if (op.numeroClient != null || op.nomClient != null)
              Text(
                [op.numeroClient, op.nomClient]
                    .where((e) => e != null)
                    .join(' — '),
                style: const TextStyle(color: _textSec, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_fmt.format(op.montant)} FCFA',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold, fontSize: 13)),
          if (op.ristourneCalculee > 0)
            Text('+${_fmt.format(op.ristourneCalculee)} ristourne',
                style: const TextStyle(color: _success, fontSize: 10)),
          Text(
            DateFormat('dd/MM HH:mm').format(op.dateHeure),
            style: const TextStyle(color: _textSec, fontSize: 10),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.receipt_long_outlined, color: _textSec, size: 48),
        const SizedBox(height: 12),
        const Text('Aucune opération',
            style: TextStyle(color: _textPrim, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Les opérations apparaîtront ici',
            style: TextStyle(color: _textSec, fontSize: 12)),
      ]),
    );
  }
}
