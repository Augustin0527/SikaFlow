// lib/models/landing_config_model.dart
// Modèle de configuration dynamique de la Landing Page SikaFlow
// Toutes les sections sont configurables par le Super Admin

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Stat (barre de statistiques) ────────────────────────────────────────────
class StatConfig {
  final String valeur;
  final String label;

  const StatConfig({required this.valeur, required this.label});

  factory StatConfig.fromMap(Map<String, dynamic> d) => StatConfig(
        valeur: d['valeur'] as String? ?? '',
        label: d['label'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'valeur': valeur, 'label': label};

  StatConfig copyWith({String? valeur, String? label}) =>
      StatConfig(valeur: valeur ?? this.valeur, label: label ?? this.label);
}

// ─── Témoignage ───────────────────────────────────────────────────────────────
class TemoignageConfig {
  final String id;
  final String nom;
  final String role;
  final String ville;
  final String entreprise;
  final String texte;
  final String photoUrl;
  final int etoiles; // 1-5
  final bool actif;

  const TemoignageConfig({
    required this.id,
    required this.nom,
    required this.role,
    this.ville = '',
    required this.entreprise,
    required this.texte,
    this.photoUrl = '',
    this.etoiles = 5,
    this.actif = true,
  });

  factory TemoignageConfig.fromMap(Map<String, dynamic> d, String id) =>
      TemoignageConfig(
        id: id,
        nom: d['nom'] as String? ?? '',
        role: d['role'] as String? ?? '',
        ville: d['ville'] as String? ?? '',
        entreprise: d['entreprise'] as String? ?? '',
        texte: d['texte'] as String? ?? '',
        photoUrl: d['photoUrl'] as String? ?? '',
        etoiles: (d['etoiles'] as num?)?.toInt() ?? 5,
        actif: d['actif'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'role': role,
        'ville': ville,
        'entreprise': entreprise,
        'texte': texte,
        'photoUrl': photoUrl,
        'etoiles': etoiles,
        'actif': actif,
      };

  TemoignageConfig copyWith({
    String? nom,
    String? role,
    String? ville,
    String? entreprise,
    String? texte,
    String? photoUrl,
    int? etoiles,
    bool? actif,
  }) =>
      TemoignageConfig(
        id: id,
        nom: nom ?? this.nom,
        role: role ?? this.role,
        ville: ville ?? this.ville,
        entreprise: entreprise ?? this.entreprise,
        texte: texte ?? this.texte,
        photoUrl: photoUrl ?? this.photoUrl,
        etoiles: etoiles ?? this.etoiles,
        actif: actif ?? this.actif,
      );
}

// ─── Section Hero ─────────────────────────────────────────────────────────────
class HeroConfig {
  final String titre;
  final String titreSuite; // ex: "en toute simplicité" (gradient)
  final String sousTitre;
  final String description;
  final String ctaPrimaire;
  final String ctaSecondaire;
  final String badgeEssai;
  final String badge2;
  final String badge3;

  const HeroConfig({
    this.titre = 'Gérez vos opérations\nMobile Money',
    this.titreSuite = 'en toute simplicité',
    this.sousTitre = 'SikaFlow',
    this.description =
        'Suivi en temps réel, gestion intelligente de vos agents\n'
        'et rapports automatisés.\n\n'
        'SikaFlow connecte vos agents de terrain et centralise\n'
        'toutes vos opérations marchandes MTN, Moov et Celtiis\n'
        'dans un tableau de bord unique, clair et sécurisé.',
    this.ctaPrimaire = 'Commencer Gratuitement',
    this.ctaSecondaire = 'Se Connecter',
    this.badgeEssai = '1 mois gratuit',
    this.badge2 = 'Sync temps réel',
    this.badge3 = 'Sécurisé',
  });

  factory HeroConfig.fromMap(Map<String, dynamic> d) => HeroConfig(
        titre: d['titre'] as String? ?? 'Gérez vos opérations\nMobile Money',
        titreSuite: d['titreSuite'] as String? ?? 'en toute simplicité',
        sousTitre: d['sousTitre'] as String? ?? 'SikaFlow',
        description: d['description'] as String? ??
            'Suivi en temps réel, gestion intelligente de vos agents\net rapports automatisés.',
        ctaPrimaire: d['ctaPrimaire'] as String? ?? 'Commencer Gratuitement',
        ctaSecondaire: d['ctaSecondaire'] as String? ?? 'Se Connecter',
        badgeEssai: d['badgeEssai'] as String? ?? '1 mois gratuit',
        badge2: d['badge2'] as String? ?? 'Sync temps réel',
        badge3: d['badge3'] as String? ?? 'Sécurisé',
      );

  Map<String, dynamic> toMap() => {
        'titre': titre,
        'titreSuite': titreSuite,
        'sousTitre': sousTitre,
        'description': description,
        'ctaPrimaire': ctaPrimaire,
        'ctaSecondaire': ctaSecondaire,
        'badgeEssai': badgeEssai,
        'badge2': badge2,
        'badge3': badge3,
      };

  HeroConfig copyWith({
    String? titre,
    String? titreSuite,
    String? sousTitre,
    String? description,
    String? ctaPrimaire,
    String? ctaSecondaire,
    String? badgeEssai,
    String? badge2,
    String? badge3,
  }) =>
      HeroConfig(
        titre: titre ?? this.titre,
        titreSuite: titreSuite ?? this.titreSuite,
        sousTitre: sousTitre ?? this.sousTitre,
        description: description ?? this.description,
        ctaPrimaire: ctaPrimaire ?? this.ctaPrimaire,
        ctaSecondaire: ctaSecondaire ?? this.ctaSecondaire,
        badgeEssai: badgeEssai ?? this.badgeEssai,
        badge2: badge2 ?? this.badge2,
        badge3: badge3 ?? this.badge3,
      );
}

// ─── Section CTA (appel à l'action) ──────────────────────────────────────────
class CtaConfig {
  final String titre;
  final String description;
  final String btnPrimaire;
  final String btnSecondaire;

  const CtaConfig({
    this.titre = 'Prêt à digitaliser votre\nMobile Money ?',
    this.description =
        'Rejoignez des centaines d\'agences Mobile Money au Bénin\nqui font confiance à SikaFlow.',
    this.btnPrimaire = 'Créer mon compte',
    this.btnSecondaire = 'Me connecter',
  });

  factory CtaConfig.fromMap(Map<String, dynamic> d) => CtaConfig(
        titre: d['titre'] as String? ??
            'Prêt à digitaliser votre\nMobile Money ?',
        description: d['description'] as String? ??
            'Rejoignez des centaines d\'agences Mobile Money au Bénin\nqui font confiance à SikaFlow.',
        btnPrimaire: d['btnPrimaire'] as String? ?? 'Créer mon compte',
        btnSecondaire: d['btnSecondaire'] as String? ?? 'Me connecter',
      );

  Map<String, dynamic> toMap() => {
        'titre': titre,
        'description': description,
        'btnPrimaire': btnPrimaire,
        'btnSecondaire': btnSecondaire,
      };

  CtaConfig copyWith({
    String? titre,
    String? description,
    String? btnPrimaire,
    String? btnSecondaire,
  }) =>
      CtaConfig(
        titre: titre ?? this.titre,
        description: description ?? this.description,
        btnPrimaire: btnPrimaire ?? this.btnPrimaire,
        btnSecondaire: btnSecondaire ?? this.btnSecondaire,
      );
}

// ─── Contact & Pied de page ───────────────────────────────────────────────────
class ContactConfig {
  final String email;
  final String telephone;
  final String whatsapp;
  final String adresse;
  final String ville;
  final String pays;
  final String siteWeb;
  final String nomEntrepriseLegale;
  final String sloganFooter;
  final String copyrightTexte;

  const ContactConfig({
    this.email = 'contact@sikaflow.org',
    this.telephone = '+229 01 XX XX XX XX',
    this.whatsapp = '+229 01 XX XX XX XX',
    this.adresse = 'Cotonou',
    this.ville = 'Cotonou',
    this.pays = 'Bénin',
    this.siteWeb = 'sikaflow.org',
    this.nomEntrepriseLegale =
        'GFPEANC — Gestion Financière et Promotions des Entreprises Agricoles Non Conventionnelles',
    this.sloganFooter =
        'La solution de gestion Mobile Money made in Bénin 🇧🇯',
    this.copyrightTexte =
        '© 2025 SikaFlow — GFPEANC. Tous droits réservés. Solution Mobile Money Bénin.',
  });

  factory ContactConfig.fromMap(Map<String, dynamic> d) => ContactConfig(
        email: d['email'] as String? ?? 'contact@sikaflow.org',
        telephone: d['telephone'] as String? ?? '+229 01 XX XX XX XX',
        whatsapp: d['whatsapp'] as String? ?? '+229 01 XX XX XX XX',
        adresse: d['adresse'] as String? ?? 'Cotonou',
        ville: d['ville'] as String? ?? 'Cotonou',
        pays: d['pays'] as String? ?? 'Bénin',
        siteWeb: d['siteWeb'] as String? ?? 'sikaflow.org',
        nomEntrepriseLegale: d['nomEntrepriseLegale'] as String? ??
            'GFPEANC — Gestion Financière et Promotions des Entreprises Agricoles Non Conventionnelles',
        sloganFooter: d['sloganFooter'] as String? ??
            'La solution de gestion Mobile Money made in Bénin 🇧🇯',
        copyrightTexte: d['copyrightTexte'] as String? ??
            '© 2025 SikaFlow — GFPEANC. Tous droits réservés. Solution Mobile Money Bénin.',
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'adresse': adresse,
        'ville': ville,
        'pays': pays,
        'siteWeb': siteWeb,
        'nomEntrepriseLegale': nomEntrepriseLegale,
        'sloganFooter': sloganFooter,
        'copyrightTexte': copyrightTexte,
      };

  ContactConfig copyWith({
    String? email,
    String? telephone,
    String? whatsapp,
    String? adresse,
    String? ville,
    String? pays,
    String? siteWeb,
    String? nomEntrepriseLegale,
    String? sloganFooter,
    String? copyrightTexte,
  }) =>
      ContactConfig(
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        whatsapp: whatsapp ?? this.whatsapp,
        adresse: adresse ?? this.adresse,
        ville: ville ?? this.ville,
        pays: pays ?? this.pays,
        siteWeb: siteWeb ?? this.siteWeb,
        nomEntrepriseLegale: nomEntrepriseLegale ?? this.nomEntrepriseLegale,
        sloganFooter: sloganFooter ?? this.sloganFooter,
        copyrightTexte: copyrightTexte ?? this.copyrightTexte,
      );
}

// ─── Modèle global de config Landing ─────────────────────────────────────────
class LandingConfig {
  final HeroConfig hero;
  final List<StatConfig> stats;
  final CtaConfig cta;
  final ContactConfig contact;
  final List<TemoignageConfig> temoignages;
  final bool maintenanceMode;
  final String messagesMaintenance;

  const LandingConfig({
    this.hero = const HeroConfig(),
    this.stats = const [],
    this.cta = const CtaConfig(),
    this.contact = const ContactConfig(),
    this.temoignages = const [],
    this.maintenanceMode = false,
    this.messagesMaintenance = 'Site en maintenance, revenez bientôt.',
  });

  // ── Valeurs par défaut ─────────────────────────────────────────────────────
  static LandingConfig defaut() => LandingConfig(
        hero: const HeroConfig(),
        stats: const [
          StatConfig(valeur: '3', label: 'Opérateurs couverts'),
          StatConfig(valeur: '30 jours', label: 'Essai gratuit'),
          StatConfig(valeur: '100%', label: 'Données privées'),
          StatConfig(valeur: '99.9%', label: 'Disponibilité'),
        ],
        cta: const CtaConfig(),
        contact: const ContactConfig(),
        temoignages: [
          TemoignageConfig(
            id: 't1',
            nom: 'Adjoua Fatima K.',
            role: 'Gestionnaire Mobile Money',
            ville: 'Cotonou',
            entreprise: 'MoneyPro Cotonou',
            texte:
                'SikaFlow a transformé ma façon de gérer mes agents. Je vois en temps réel les soldes de chacun, et mes ristournes sont calculées automatiquement. Je gagne 2 heures par jour !',
            photoUrl:
                'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=120&h=120&fit=crop&crop=face',
            etoiles: 5,
          ),
          TemoignageConfig(
            id: 't2',
            nom: 'Kofi Mensah',
            role: 'Agent Mobile Money',
            ville: 'Porto-Novo',
            entreprise: 'CashPoint Porto-Novo',
            texte:
                'Avant je notais tout dans un cahier. Maintenant je soumets mon point journalier en 2 minutes depuis mon téléphone. Mon gestionnaire valide rapidement et tout est enregistré.',
            photoUrl:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&crop=face',
            etoiles: 5,
          ),
          TemoignageConfig(
            id: 't3',
            nom: 'Aïssatou Diallo',
            role: 'Contrôleure de zone',
            ville: 'Parakou',
            entreprise: 'FlexMoney Abomey',
            texte:
                'Je supervise 8 agents. SikaFlow me donne une vue claire sur chaque opérateur. Les rapports sont automatiques, je peux me concentrer sur le terrain.',
            photoUrl:
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120&h=120&fit=crop&crop=face',
            etoiles: 5,
          ),
        ],
      );

  factory LandingConfig.fromFirestore(Map<String, dynamic> d) {
    // Stats
    final rawStats = d['stats'] as List? ?? [];
    final stats = rawStats
        .map((e) => StatConfig.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Témoignages
    final rawTem = d['temoignages'] as List? ?? [];
    final tems = rawTem
        .asMap()
        .entries
        .map((e) => TemoignageConfig.fromMap(
            Map<String, dynamic>.from(e.value as Map), 't${e.key}'))
        .toList();

    return LandingConfig(
      hero: d['hero'] != null
          ? HeroConfig.fromMap(Map<String, dynamic>.from(d['hero'] as Map))
          : const HeroConfig(),
      stats: stats.isNotEmpty
          ? stats
          : const [
              StatConfig(valeur: '3', label: 'Opérateurs couverts'),
              StatConfig(valeur: '30 jours', label: 'Essai gratuit'),
              StatConfig(valeur: '100%', label: 'Données privées'),
              StatConfig(valeur: '99.9%', label: 'Disponibilité'),
            ],
      cta: d['cta'] != null
          ? CtaConfig.fromMap(Map<String, dynamic>.from(d['cta'] as Map))
          : const CtaConfig(),
      contact: d['contact'] != null
          ? ContactConfig.fromMap(
              Map<String, dynamic>.from(d['contact'] as Map))
          : const ContactConfig(),
      temoignages: tems,
      maintenanceMode: d['maintenanceMode'] as bool? ?? false,
      messagesMaintenance:
          d['messagesMaintenance'] as String? ?? 'Site en maintenance.',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hero': hero.toMap(),
        'stats': stats.map((s) => s.toMap()).toList(),
        'cta': cta.toMap(),
        'contact': contact.toMap(),
        'temoignages': temoignages.map((t) => t.toMap()).toList(),
        'maintenanceMode': maintenanceMode,
        'messagesMaintenance': messagesMaintenance,
        'updated_at': FieldValue.serverTimestamp(),
      };
}
