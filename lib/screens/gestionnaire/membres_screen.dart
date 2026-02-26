import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';

const _bg       = Color(0xFF1E2530);
const _surface  = Color(0xFF252D3A);
const _surfaceHi= Color(0xFF2C3547);
const _border   = Color(0xFF313D52);
const _orange   = Color(0xFFFF6B35);
const _success  = Color(0xFF00C896);
const _error    = Color(0xFFFF4444);
const _textPrim = Color(0xFFF0F4F8);
const _textSec  = Color(0xFF8A9BB0);

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      return Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Header + tabs
            Container(
              color: const Color(0xFF1A2130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Membres',
                        style: TextStyle(
                            color: _textPrim,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TabBar(
                    controller: _tabs,
                    indicatorColor: _orange,
                    labelColor: _orange,
                    unselectedLabelColor: _textSec,
                    tabs: [
                      Tab(text: 'Agents (${p.agents.length})'),
                      Tab(text: 'Contrôleurs (${p.controleurs.length})'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildListeMembres(p.agents, 'agent', p),
                  _buildListeMembres(p.controleurs, 'controleur', p),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _orange,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Ajouter',
              style: TextStyle(color: Colors.white)),
          onPressed: () => _showAjouterMembreDialog(context, p),
        ),
      );
    });
  }

  Widget _buildListeMembres(
      List<UserModel> membres, String role, AppProvider p) {
    if (membres.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            role == 'agent'
                ? Icons.person_outlined
                : Icons.admin_panel_settings_outlined,
            color: _textSec, size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun ${role == 'agent' ? 'agent' : 'contrôleur'}',
            style: const TextStyle(
                color: _textPrim, fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('Appuyez sur + pour en ajouter',
              style: TextStyle(color: _textSec, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: membres.length,
      itemBuilder: (_, i) => _buildMembreCard(membres[i], p),
    );
  }

  Widget _buildMembreCard(UserModel user, AppProvider p) {
    final isActive = user.actif;
    final stand = p.stands
        .where((s) => s.agentActuelId == user.id)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [_orange, const Color(0xFFFF9500)]
                  : [_textSec, const Color(0xFF607D8B)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '${user.prenom.isNotEmpty ? user.prenom[0] : '?'}${user.nom.isNotEmpty ? user.nom[0] : ''}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${user.prenom} ${user.nom}',
                style: const TextStyle(
                    color: _textPrim, fontWeight: FontWeight.bold)),
            Text(user.email ?? '',
                style: const TextStyle(color: _textSec, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            if (stand != null)
              Row(children: [
                const Icon(Icons.store_rounded, color: _success, size: 12),
                const SizedBox(width: 4),
                Text(stand.nom,
                    style: const TextStyle(
                        color: _success, fontSize: 11)),
              ]),
          ]),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isActive ? _success : _error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: isActive ? _success : _error,
                  fontSize: 10, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(user.role,
                  style: const TextStyle(
                      color: _orange, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ]),
    );
  }

  void _showAjouterMembreDialog(BuildContext ctx, AppProvider p) {
    final prenomCtrl = TextEditingController();
    final nomCtrl    = TextEditingController();
    final emailCtrl  = TextEditingController();
    final telCtrl    = TextEditingController();
    String role = 'agent';
    bool loading = false;
    String? erreur;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(builder: (ctx2, ss) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Ajouter un membre',
            style: TextStyle(color: _textPrim)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (erreur != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(erreur!,
                    style: const TextStyle(color: _error, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            _dialogField('Prénom', prenomCtrl),
            const SizedBox(height: 10),
            _dialogField('Nom', nomCtrl),
            const SizedBox(height: 10),
            _dialogField('Email', emailCtrl,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _dialogField('Téléphone', telCtrl,
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: role,
              dropdownColor: _surfaceHi,
              style: const TextStyle(color: _textPrim),
              decoration: InputDecoration(
                labelText: 'Rôle',
                labelStyle: const TextStyle(color: _textSec),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border)),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'agent', child: Text('Agent')),
                DropdownMenuItem(
                    value: 'controleur', child: Text('Contrôleur')),
              ],
              onChanged: (v) => ss(() => role = v!),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Annuler',
                style: TextStyle(color: _textSec)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _orange),
            onPressed: loading
                ? null
                : () async {
                    if (prenomCtrl.text.isEmpty ||
                        emailCtrl.text.isEmpty) {
                      ss(() => erreur = 'Prénom et email requis');
                      return;
                    }
                    ss(() {
                      loading = true;
                      erreur = null;
                    });
                    final result = await p.ajouterMembre(
                      email: emailCtrl.text.trim(),
                      prenom: prenomCtrl.text.trim(),
                      nom: nomCtrl.text.trim(),
                      telephone: telCtrl.text.trim(),
                      role: role,
                    );
                    if (result['success'] == true) {
                      if (ctx2.mounted) Navigator.pop(ctx2);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: const Text('Membre ajouté avec succès'),
                            backgroundColor: _success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } else {
                      ss(() {
                        loading = false;
                        erreur = result['erreur'] ?? 'Erreur inconnue';
                      });
                    }
                  },
            child: loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Ajouter',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: _textPrim),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSec),
        filled: true,
        fillColor: _bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _orange, width: 2)),
      ),
    );
  }
}
