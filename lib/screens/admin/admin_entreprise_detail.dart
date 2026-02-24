import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminEntrepriseDetail extends StatefulWidget {
  final String entrepriseId;
  final Map<String, dynamic> data;
  const AdminEntrepriseDetail({super.key, required this.entrepriseId, required this.data});

  @override
  State<AdminEntrepriseDetail> createState() => _AdminEntrepriseDetailState();
}

class _AdminEntrepriseDetailState extends State<AdminEntrepriseDetail> {
  final _fs = FirestoreService();
  bool _chargement = false;

  Future<void> _changerStatut(String statut) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Confirmer', style: TextStyle(color: Colors.white)),
        content: Text(
          statut == 'suspendu'
              ? 'Suspendre l\'accès à "${widget.data['nom']}" ?'
              : 'Réactiver "${widget.data['nom']}" ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: statut == 'suspendu' ? Colors.red : Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(statut == 'suspendu' ? 'Suspendre' : 'Activer', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      setState(() => _chargement = true);
      await _fs.changerStatutEntreprise(widget.entrepriseId, statut);
      if (mounted) {
        setState(() => _chargement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour : $statut'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final statut = widget.data['statut'] ?? 'essai';
    final expiration = (widget.data['date_expiration_abonnement'] as Timestamp?)?.toDate();
    final creation = (widget.data['date_creation'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        title: Text(widget.data['nom'] ?? 'Entreprise', style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Infos entreprise
                _section('Informations', [
                  _infoRow('Nom', widget.data['nom'] ?? '-'),
                  _infoRow('Capital de départ', '${fmt.format(widget.data['capital_depart'] ?? 0)} FCFA'),
                  _infoRow('Statut', statut.toUpperCase()),
                  if (creation != null) _infoRow('Créée le', DateFormat('dd/MM/yyyy').format(creation)),
                  if (expiration != null) _infoRow('Expiration', DateFormat('dd/MM/yyyy').format(expiration)),
                ]),
                const SizedBox(height: 16),

                // Membres
                _section('Membres', [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Future.wait([
                      _fs.getMembresParRole(widget.entrepriseId, 'agent'),
                      _fs.getMembresParRole(widget.entrepriseId, 'controleur'),
                    ]).then((r) => [...r[0], ...r[1]]),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      final membres = snap.data!;
                      if (membres.isEmpty) return const Text('Aucun membre', style: TextStyle(color: Colors.white54));
                      return Column(
                        children: membres.map((m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: m['role'] == 'agent' ? Colors.blue.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.2),
                            child: Icon(
                              m['role'] == 'agent' ? Icons.person : Icons.supervisor_account,
                              color: m['role'] == 'agent' ? Colors.blue : Colors.purple,
                              size: 16,
                            ),
                          ),
                          title: Text('${m['prenom']} ${m['nom']}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(m['role'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (m['actif'] == true ? Colors.green : Colors.red).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m['actif'] == true ? 'Actif' : 'Inactif',
                              style: TextStyle(color: m['actif'] == true ? Colors.green : Colors.red, fontSize: 11),
                            ),
                          ),
                        )).toList(),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Actions admin
                const Text('Actions administrateur', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (statut != 'suspendu')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.block, color: Colors.white),
                      label: const Text('Suspendre l\'entreprise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _changerStatut('suspendu'),
                    ),
                  ),
                if (statut == 'suspendu') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('Réactiver l\'entreprise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _changerStatut('actif'),
                    ),
                  ),
                ],
              ]),
            ),
    );
  }

  Widget _section(String titre, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const Divider(color: Colors.white12, height: 20),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        Expanded(flex: 3, child: Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
