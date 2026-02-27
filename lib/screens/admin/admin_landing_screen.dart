// lib/screens/admin/admin_landing_screen.dart
// Panneau de configuration de la Landing Page — Super Admin SikaFlow

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/landing_config_model.dart';
import '../../theme/app_theme.dart';

class AdminLandingScreen extends StatefulWidget {
  const AdminLandingScreen({super.key});

  @override
  State<AdminLandingScreen> createState() => _AdminLandingScreenState();
}

class _AdminLandingScreenState extends State<AdminLandingScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late TabController _tabs;

  LandingConfig _config = LandingConfig.defaut();
  bool _chargement = true;
  bool _sauvegarde = false;

  // ── Controllers Hero ───────────────────────────────────────────────────────
  late TextEditingController _titreCtrl;
  late TextEditingController _titreSuiteCtrl;
  late TextEditingController _sousTitreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ctaPrimCtrl;
  late TextEditingController _ctaSecCtrl;
  late TextEditingController _badgeEssaiCtrl;
  late TextEditingController _badge2Ctrl;
  late TextEditingController _badge3Ctrl;

  // ── Controllers CTA ────────────────────────────────────────────────────────
  late TextEditingController _ctaTitreCtrl;
  late TextEditingController _ctaDescCtrl;
  late TextEditingController _ctaBtn1Ctrl;
  late TextEditingController _ctaBtn2Ctrl;

  // ── Controllers Contact ────────────────────────────────────────────────────
  late TextEditingController _emailCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _waCtrl;
  late TextEditingController _adresseCtrl;
  late TextEditingController _villeCtrl;
  late TextEditingController _paysCtrl;
  late TextEditingController _siteCtrl;
  late TextEditingController _nomEntrepriseCtrl;
  late TextEditingController _sloganFooterCtrl;
  late TextEditingController _copyrightCtrl;

  // ── Stats (modifiées inline) ────────────────────────────────────────────────
  List<StatConfig> _stats = [];

  // ── Témoignages (modifiés inline) ──────────────────────────────────────────
  List<TemoignageConfig> _temoignages = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _initControllers();
    _charger();
  }

  void _initControllers() {
    final h = _config.hero;
    final c = _config.contact;
    final cta = _config.cta;

    _titreCtrl = TextEditingController(text: h.titre);
    _titreSuiteCtrl = TextEditingController(text: h.titreSuite);
    _sousTitreCtrl = TextEditingController(text: h.sousTitre);
    _descCtrl = TextEditingController(text: h.description);
    _ctaPrimCtrl = TextEditingController(text: h.ctaPrimaire);
    _ctaSecCtrl = TextEditingController(text: h.ctaSecondaire);
    _badgeEssaiCtrl = TextEditingController(text: h.badgeEssai);
    _badge2Ctrl = TextEditingController(text: h.badge2);
    _badge3Ctrl = TextEditingController(text: h.badge3);

    _ctaTitreCtrl = TextEditingController(text: cta.titre);
    _ctaDescCtrl = TextEditingController(text: cta.description);
    _ctaBtn1Ctrl = TextEditingController(text: cta.btnPrimaire);
    _ctaBtn2Ctrl = TextEditingController(text: cta.btnSecondaire);

    _emailCtrl = TextEditingController(text: c.email);
    _telCtrl = TextEditingController(text: c.telephone);
    _waCtrl = TextEditingController(text: c.whatsapp);
    _adresseCtrl = TextEditingController(text: c.adresse);
    _villeCtrl = TextEditingController(text: c.ville);
    _paysCtrl = TextEditingController(text: c.pays);
    _siteCtrl = TextEditingController(text: c.siteWeb);
    _nomEntrepriseCtrl = TextEditingController(text: c.nomEntrepriseLegale);
    _sloganFooterCtrl = TextEditingController(text: c.sloganFooter);
    _copyrightCtrl = TextEditingController(text: c.copyrightTexte);

    _stats = List.from(_config.stats);
    _temoignages = List.from(_config.temoignages);
  }

  Future<void> _charger() async {
    try {
      final doc = await _db.collection('config_landing').doc('main').get();
      if (doc.exists && mounted) {
        final cfg = LandingConfig.fromFirestore(doc.data()!);
        setState(() {
          _config = cfg;
          _chargement = false;
        });
        _miseAJourControllers();
      } else {
        if (mounted) setState(() => _chargement = false);
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _miseAJourControllers() {
    final h = _config.hero;
    final c = _config.contact;
    final cta = _config.cta;

    _titreCtrl.text = h.titre;
    _titreSuiteCtrl.text = h.titreSuite;
    _sousTitreCtrl.text = h.sousTitre;
    _descCtrl.text = h.description;
    _ctaPrimCtrl.text = h.ctaPrimaire;
    _ctaSecCtrl.text = h.ctaSecondaire;
    _badgeEssaiCtrl.text = h.badgeEssai;
    _badge2Ctrl.text = h.badge2;
    _badge3Ctrl.text = h.badge3;

    _ctaTitreCtrl.text = cta.titre;
    _ctaDescCtrl.text = cta.description;
    _ctaBtn1Ctrl.text = cta.btnPrimaire;
    _ctaBtn2Ctrl.text = cta.btnSecondaire;

    _emailCtrl.text = c.email;
    _telCtrl.text = c.telephone;
    _waCtrl.text = c.whatsapp;
    _adresseCtrl.text = c.adresse;
    _villeCtrl.text = c.ville;
    _paysCtrl.text = c.pays;
    _siteCtrl.text = c.siteWeb;
    _nomEntrepriseCtrl.text = c.nomEntrepriseLegale;
    _sloganFooterCtrl.text = c.sloganFooter;
    _copyrightCtrl.text = c.copyrightTexte;

    _stats = List.from(_config.stats);
    _temoignages = List.from(_config.temoignages);
  }

  Future<void> _sauvegarder() async {
    setState(() => _sauvegarde = true);
    try {
      final newConfig = LandingConfig(
        hero: HeroConfig(
          titre: _titreCtrl.text,
          titreSuite: _titreSuiteCtrl.text,
          sousTitre: _sousTitreCtrl.text,
          description: _descCtrl.text,
          ctaPrimaire: _ctaPrimCtrl.text,
          ctaSecondaire: _ctaSecCtrl.text,
          badgeEssai: _badgeEssaiCtrl.text,
          badge2: _badge2Ctrl.text,
          badge3: _badge3Ctrl.text,
        ),
        stats: _stats,
        cta: CtaConfig(
          titre: _ctaTitreCtrl.text,
          description: _ctaDescCtrl.text,
          btnPrimaire: _ctaBtn1Ctrl.text,
          btnSecondaire: _ctaBtn2Ctrl.text,
        ),
        contact: ContactConfig(
          email: _emailCtrl.text,
          telephone: _telCtrl.text,
          whatsapp: _waCtrl.text,
          adresse: _adresseCtrl.text,
          ville: _villeCtrl.text,
          pays: _paysCtrl.text,
          siteWeb: _siteCtrl.text,
          nomEntrepriseLegale: _nomEntrepriseCtrl.text,
          sloganFooter: _sloganFooterCtrl.text,
          copyrightTexte: _copyrightCtrl.text,
        ),
        temoignages: _temoignages,
      );

      await _db.collection('config_landing').doc('main').set(
        newConfig.toFirestore(),
        SetOptions(merge: false),
      );

      if (mounted) {
        setState(() => _config = newConfig);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Landing page mise à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sauvegarde = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _titreCtrl, _titreSuiteCtrl, _sousTitreCtrl, _descCtrl,
      _ctaPrimCtrl, _ctaSecCtrl, _badgeEssaiCtrl, _badge2Ctrl, _badge3Ctrl,
      _ctaTitreCtrl, _ctaDescCtrl, _ctaBtn1Ctrl, _ctaBtn2Ctrl,
      _emailCtrl, _telCtrl, _waCtrl, _adresseCtrl, _villeCtrl, _paysCtrl,
      _siteCtrl, _nomEntrepriseCtrl, _sloganFooterCtrl, _copyrightCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange));
    }

    return Column(
      children: [
        // ── Barre d'onglets ─────────────────────────────────────────────────
        Container(
          color: AppTheme.cardDarker,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: AppTheme.accentOrange,
            labelColor: AppTheme.accentOrange,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Hero'),
              Tab(text: 'Stats & CTA'),
              Tab(text: 'Témoignages'),
              Tab(text: 'Contact & Footer'),
              Tab(text: 'Aperçu'),
            ],
          ),
        ),

        // ── Contenu ─────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _tabHero(),
              _tabStatsCta(),
              _tabTemoignages(),
              _tabContact(),
              _tabApercu(),
            ],
          ),
        ),

        // ── Bouton sauvegarder ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDarker,
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sauvegarde ? null : _sauvegarder,
              icon: _sauvegarde
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_sauvegarde ? 'Sauvegarde...' : 'Sauvegarder la landing page'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ONGLET HERO
  // ════════════════════════════════════════════════════════════════════════════
  Widget _tabHero() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Section Héro', Icons.auto_awesome),
        const SizedBox(height: 16),
        _field('Titre principal (ligne 1)', _titreCtrl, maxLines: 2,
            hint: 'ex: Gérez vos opérations\nMobile Money'),
        _field('Titre suite (gradient)', _titreSuiteCtrl,
            hint: 'ex: en toute simplicité'),
        _field('Sous-titre / Badge catégorie', _sousTitreCtrl,
            hint: 'ex: Système de gestion des opérations...'),
        _field('Description', _descCtrl, maxLines: 5,
            hint: 'Texte de présentation sous le titre'),
        const SizedBox(height: 20),
        _sectionTitle('Boutons d\'action', Icons.touch_app),
        const SizedBox(height: 16),
        _field('Bouton primaire (orange)', _ctaPrimCtrl,
            hint: 'ex: Commencer Gratuitement'),
        _field('Bouton secondaire', _ctaSecCtrl,
            hint: 'ex: Se Connecter'),
        const SizedBox(height: 20),
        _sectionTitle('Badges (sous les boutons)', Icons.verified_outlined),
        const SizedBox(height: 16),
        _field('Badge 1 (avec bouclier)', _badgeEssaiCtrl,
            hint: 'ex: 1 mois gratuit'),
        _field('Badge 2 (avec sync)', _badge2Ctrl,
            hint: 'ex: Sync temps réel'),
        _field('Badge 3 (avec cadenas)', _badge3Ctrl,
            hint: 'ex: Sécurisé'),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ONGLET STATS & CTA
  // ════════════════════════════════════════════════════════════════════════════
  Widget _tabStatsCta() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Statistiques ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Barre de statistiques', Icons.bar_chart),
            TextButton.icon(
              onPressed: _ajouterStat,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Ces chiffres apparaissent sous le héro.',
            style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
        const SizedBox(height: 12),
        ..._stats.asMap().entries.map((e) => _statEditor(e.key, e.value)),

        const Divider(color: AppTheme.divider, height: 40),

        // ── Section CTA ──────────────────────────────────────────────────
        _sectionTitle('Section appel à l\'action (CTA)', Icons.campaign_outlined),
        const SizedBox(height: 16),
        _field('Titre CTA', _ctaTitreCtrl, maxLines: 2,
            hint: 'ex: Prêt à digitaliser votre\nMobile Money ?'),
        _field('Description CTA', _ctaDescCtrl, maxLines: 3,
            hint: 'ex: Rejoignez des centaines d\'agences...'),
        _field('Bouton primaire CTA', _ctaBtn1Ctrl,
            hint: 'ex: Créer mon compte'),
        _field('Bouton secondaire CTA', _ctaBtn2Ctrl,
            hint: 'ex: Me connecter'),
      ],
    );
  }

  Widget _statEditor(int index, StatConfig stat) {
    final valCtrl = TextEditingController(text: stat.valeur);
    final labCtrl = TextEditingController(text: stat.label);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDarker,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: valCtrl,
                  decoration: _inputDeco('Valeur', hint: 'ex: 500+'),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => _stats[index] = stat.copyWith(valeur: v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: labCtrl,
                  decoration: _inputDeco('Label', hint: 'ex: Agents actifs'),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => _stats[index] = stat.copyWith(label: v),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => setState(() => _stats.removeAt(index)),
          ),
        ],
      ),
    );
  }

  void _ajouterStat() {
    setState(() => _stats.add(const StatConfig(valeur: '', label: '')));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ONGLET TÉMOIGNAGES
  // ════════════════════════════════════════════════════════════════════════════
  Widget _tabTemoignages() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Témoignages clients', Icons.format_quote),
            TextButton.icon(
              onPressed: _ajouterTemoignage,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._temoignages.asMap().entries.map((e) => _temoignageEditor(e.key, e.value)),
      ],
    );
  }

  Widget _temoignageEditor(int index, TemoignageConfig t) {
    final nomCtrl = TextEditingController(text: t.nom);
    final roleCtrl = TextEditingController(text: t.role);
    final villeCtrl = TextEditingController(text: t.ville);
    final entrepriseCtrl = TextEditingController(text: t.entreprise);
    final texteCtrl = TextEditingController(text: t.texte);
    final photoCtrl = TextEditingController(text: t.photoUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDarker,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text('Témoignage ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: t.actif,
                  activeThumbColor: AppTheme.accentOrange,
                  onChanged: (v) => setState(
                      () => _temoignages[index] = t.copyWith(actif: v)),
                ),
                const SizedBox(width: 4),
                Text(t.actif ? 'Visible' : 'Masqué',
                    style: TextStyle(
                        color: t.actif ? Colors.green : AppTheme.textHint,
                        fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _temoignages.removeAt(index)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: TextField(
                    controller: nomCtrl,
                    decoration: _inputDeco('Nom'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => _temoignages[index] = t.copyWith(nom: v),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: roleCtrl,
                    decoration: _inputDeco('Rôle'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => _temoignages[index] = t.copyWith(role: v),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: villeCtrl,
                    decoration: _inputDeco('Ville'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => _temoignages[index] = t.copyWith(ville: v),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: entrepriseCtrl,
                    decoration: _inputDeco('Entreprise'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => _temoignages[index] = t.copyWith(entreprise: v),
                  )),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: texteCtrl,
                  decoration: _inputDeco('Texte du témoignage'),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  onChanged: (v) => _temoignages[index] = t.copyWith(texte: v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: photoCtrl,
                  decoration: _inputDeco('URL photo profil', hint: 'https://...'),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => _temoignages[index] = t.copyWith(photoUrl: v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Étoiles :', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    ...List.generate(5, (i) => GestureDetector(
                      onTap: () => setState(() =>
                          _temoignages[index] = t.copyWith(etoiles: i + 1)),
                      child: Icon(
                        i < t.etoiles ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppTheme.accentOrange,
                        size: 24,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _ajouterTemoignage() {
    setState(() => _temoignages.add(TemoignageConfig(
      id: 't${DateTime.now().millisecondsSinceEpoch}',
      nom: '',
      role: '',
      entreprise: '',
      texte: '',
    )));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ONGLET CONTACT & FOOTER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _tabContact() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Coordonnées de contact', Icons.contact_phone_outlined),
        const SizedBox(height: 16),
        _field('Email', _emailCtrl, hint: 'contact@sikaflow.org'),
        _field('Téléphone', _telCtrl, hint: '+229 01 XX XX XX XX'),
        _field('WhatsApp', _waCtrl, hint: '+229 01 XX XX XX XX'),
        _field('Adresse', _adresseCtrl, hint: 'Rue...'),
        Row(children: [
          Expanded(child: _field('Ville', _villeCtrl, hint: 'Cotonou')),
          const SizedBox(width: 12),
          Expanded(child: _field('Pays', _paysCtrl, hint: 'Bénin')),
        ]),
        _field('Site web', _siteCtrl, hint: 'sikaflow.org'),
        const Divider(color: AppTheme.divider, height: 32),
        _sectionTitle('Pied de page (Footer)', Icons.article_outlined),
        const SizedBox(height: 16),
        _field('Nom entreprise légale', _nomEntrepriseCtrl, maxLines: 2,
            hint: 'GFPEANC — Gestion Financière...'),
        _field('Slogan footer', _sloganFooterCtrl,
            hint: 'La solution Mobile Money made in Bénin 🇧🇯'),
        _field('Texte copyright', _copyrightCtrl, maxLines: 2,
            hint: '© 2025 SikaFlow — Tous droits réservés.'),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ONGLET APERÇU
  // ════════════════════════════════════════════════════════════════════════════
  Widget _tabApercu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Aperçu de la configuration', Icons.preview),
          const SizedBox(height: 16),

          // Hero
          _apercuSection('HÉRO', [
            _apercuLigne('Titre', _titreCtrl.text),
            _apercuLigne('Suite titre (gradient)', _titreSuiteCtrl.text),
            _apercuLigne('Sous-titre', _sousTitreCtrl.text),
            _apercuLigne('Bouton 1', _ctaPrimCtrl.text),
            _apercuLigne('Bouton 2', _ctaSecCtrl.text),
            _apercuLigne('Badge 1', _badgeEssaiCtrl.text),
          ]),

          // Stats
          _apercuSection('STATISTIQUES', _stats.map(
            (s) => _apercuLigne(s.label, s.valeur)).toList()),

          // CTA
          _apercuSection('CTA', [
            _apercuLigne('Titre', _ctaTitreCtrl.text),
            _apercuLigne('Description', _ctaDescCtrl.text),
          ]),

          // Témoignages
          _apercuSection('TÉMOIGNAGES (${_temoignages.where((t) => t.actif).length} actifs)',
            _temoignages.map((t) => _apercuLigne(
              '${t.actif ? "✅" : "🔴"} ${t.nom}',
              '${t.role} — ${t.ville}')).toList()),

          // Contact
          _apercuSection('CONTACT', [
            _apercuLigne('Email', _emailCtrl.text),
            _apercuLigne('Téléphone', _telCtrl.text),
            _apercuLigne('WhatsApp', _waCtrl.text),
            _apercuLigne('Ville', '${_villeCtrl.text}, ${_paysCtrl.text}'),
            _apercuLigne('Site', _siteCtrl.text),
          ]),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Les modifications sont publiées immédiatement sur la landing page publique après sauvegarde.',
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _apercuSection(String titre, List<Widget> lignes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDarker,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Text(titre,
                style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: lignes),
          ),
        ],
      ),
    );
  }

  Widget _apercuLigne(String cle, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(cle,
                style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              valeur.isEmpty ? '(vide)' : valeur,
              style: TextStyle(
                  color: valeur.isEmpty ? AppTheme.textHint : Colors.white,
                  fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: _inputDeco(label, hint: hint),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
      filled: true,
      fillColor: AppTheme.backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _sectionTitle(String titre, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentOrange, size: 18),
        const SizedBox(width: 8),
        Text(titre,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}
