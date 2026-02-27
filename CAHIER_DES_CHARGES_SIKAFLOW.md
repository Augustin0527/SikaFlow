# CAHIER DES CHARGES
# SikaFlow — Application Mobile & Web de Gestion des Opérations Mobile Money

---

**Version :** 1.0  
**Date :** Juin 2025  
**Maître d'ouvrage :** GFPEANC  
**Domaine :** https://sikaflow.org  
**Plateforme :** Application Flutter (Android + Web)  
**Backend :** Firebase (Firestore, Auth, Hosting, Storage)  
**Paiement :** FedaPay (MTN, Moov, Celtiis — FCFA)

---

## TABLE DES MATIÈRES

1. [Présentation du projet](#1-présentation-du-projet)
2. [Contexte et problématique](#2-contexte-et-problématique)
3. [Objectifs](#3-objectifs)
4. [Périmètre fonctionnel](#4-périmètre-fonctionnel)
5. [Acteurs et rôles](#5-acteurs-et-rôles)
6. [Fonctionnalités détaillées](#6-fonctionnalités-détaillées)
7. [Architecture technique](#7-architecture-technique)
8. [Modèle de données](#8-modèle-de-données)
9. [Modèle économique et abonnements](#9-modèle-économique-et-abonnements)
10. [Interfaces utilisateur](#10-interfaces-utilisateur)
11. [Sécurité et conformité](#11-sécurité-et-conformité)
12. [Performances et contraintes](#12-performances-et-contraintes)
13. [Déploiement et infrastructure](#13-déploiement-et-infrastructure)
14. [Jalons et livrables](#14-jalons-et-livrables)
15. [Glossaire](#15-glossaire)

---

## 1. PRÉSENTATION DU PROJET

### 1.1 Identité de l'application

| Champ            | Valeur                                             |
|------------------|----------------------------------------------------|
| Nom              | **SikaFlow**                                       |
| Slogan           | *Gérez vos opérations Mobile Money en toute sérénité* |
| Domaine          | https://sikaflow.org                               |
| Package Android  | com.mobilemoneycontrol.control                    |
| Version initiale | 1.0.0                                              |
| Langues          | Français (principal)                               |
| Marchés cibles   | Bénin (MTN, Moov, Celtiis) — extension UEMOA prévue |

### 1.2 Résumé

SikaFlow est une plateforme SaaS (Software as a Service) multi-tenant destinée aux agences et entrepreneurs du secteur Mobile Money au Bénin. Elle permet à une entreprise de gérer, en temps réel, l'ensemble de ses points de vente (« stands »), ses agents terrain, ses contrôleurs, ses soldes SIM et ses opérations financières (dépôts, retraits, crédits forfaits) via une application mobile Android et une interface web progressive.

---

## 2. CONTEXTE ET PROBLÉMATIQUE

### 2.1 Secteur Mobile Money au Bénin

Le Mobile Money connaît une croissance forte au Bénin avec trois opérateurs majeurs :
- **MTN Mobile Money (MoMo)**
- **Moov Money**
- **Celtiis Cash**

Les agences agréées gèrent plusieurs points de vente (stands) avec des agents qui réalisent des transactions quotidiennes (dépôts, retraits, crédits forfaits). La gestion de ces opérations est aujourd'hui majoritairement manuelle (cahiers, tableaux Excel), ce qui génère :

- Des erreurs de saisie et des pertes financières non détectées
- Une absence de visibilité en temps réel sur les soldes SIM et espèces
- Des difficultés de supervision à distance des agents
- Une gestion inefficace des rééquilibrages de liquidités
- Aucun système d'alerte en cas d'anomalie de solde

### 2.2 Problèmes résolus par SikaFlow

| Problème actuel               | Solution SikaFlow                              |
|-------------------------------|------------------------------------------------|
| Gestion manuelle (cahier)     | Saisie numérique en temps réel                 |
| Pas de visibilité à distance  | Tableau de bord superviseur en temps réel      |
| Erreurs de calcul de ristourne| Calcul automatique des commissions             |
| Rééquilibrage non organisé    | Système de demandes et d'approbation           |
| Aucune alerte de solde bas    | Alertes automatiques configurables             |
| Pas de rapports financiers    | Exports et rapports consolidés                 |

---

## 3. OBJECTIFS

### 3.1 Objectifs fonctionnels

- **OF-01** : Permettre l'inscription et la gestion autonome d'une entreprise Mobile Money
- **OF-02** : Gérer plusieurs stands (points de vente) avec leurs SIM (MTN, Moov, Celtiis)
- **OF-03** : Permettre aux agents de saisir les opérations en temps réel
- **OF-04** : Offrir une supervision complète des gestionnaires et contrôleurs
- **OF-05** : Automatiser le calcul des ristournes (commissions agents)
- **OF-06** : Gérer les alertes de solde bas et les demandes de rééquilibrage
- **OF-07** : Produire des rapports financiers consolidés (journaliers, hebdomadaires, mensuels)
- **OF-08** : Intégrer un système d'abonnement avec paiement FedaPay

### 3.2 Objectifs non-fonctionnels

- **ONF-01** : Disponibilité ≥ 99,5 % (SLA Firebase Hosting)
- **ONF-02** : Temps de chargement page web < 2 secondes (réseau 4G)
- **ONF-03** : Données synchronisées en temps réel (< 1 seconde Firestore)
- **ONF-04** : Application utilisable hors connexion (saisie offline avec sync)
- **ONF-05** : Sécurité des données financières (chiffrement TLS, Auth Firebase)
- **ONF-06** : Interface intuitive utilisable sans formation technique avancée

---

## 4. PÉRIMÈTRE FONCTIONNEL

### 4.1 Dans le périmètre (V1)

✅ Gestion multi-entreprises (SaaS multi-tenant)  
✅ Gestion des stands et des SIM cards  
✅ Saisie des opérations (dépôt, retrait, crédit forfait)  
✅ Tableau de bord temps réel par rôle  
✅ Système d'alertes configurables  
✅ Demandes et approbations de rééquilibrage  
✅ Calcul automatique des ristournes  
✅ Rapports financiers et exports  
✅ Système d'abonnement avec essai gratuit 30 jours  
✅ Paiement FedaPay (Mobile Money)  
✅ Super Admin avec tableau de bord global  
✅ Application Android + Progressive Web App  
✅ Authentification Firebase (email/mot de passe)  
✅ Landing page marketing publique  

### 4.2 Hors périmètre (V2 et ultérieures)

❌ Application iOS native  
❌ Intégration API directe MTN/Moov/Celtiis  
❌ Module comptabilité avancée  
❌ Application desktop native  
❌ Notifications push SMS  
❌ Multilingue (Fon, Yoruba)  

---

## 5. ACTEURS ET RÔLES

L'application définit **4 rôles utilisateurs** avec des niveaux d'accès distincts, plus un rôle super administrateur global.

### 5.1 Super Admin (`super_admin`)

**Profil :** Équipe technique SikaFlow  
**Périmètre :** Toutes les entreprises de la plateforme

| Fonctionnalité                         | Accès |
|----------------------------------------|-------|
| Tableau de bord global (toutes entreprises) | ✅ |
| Liste et détail de toutes les entreprises   | ✅ |
| Gestion des abonnements (activation, suspension) | ✅ |
| Configuration des plans tarifaires          | ✅ |
| Statistiques globales (revenus, entreprises actives) | ✅ |

### 5.2 Gestionnaire (`gestionnaire`)

**Profil :** Propriétaire ou directeur d'agence Mobile Money  
**Périmètre :** Son entreprise uniquement

| Fonctionnalité                              | Accès |
|---------------------------------------------|-------|
| Tableau de bord entreprise                  | ✅ |
| Créer / modifier / désactiver des stands    | ✅ |
| Gérer les agents (inviter, affecter, désaffecter) | ✅ |
| Gérer les contrôleurs et leurs permissions  | ✅ |
| Initialiser les soldes (espèces + SIM)      | ✅ |
| Voir toutes les opérations                  | ✅ |
| Modifier une opération (dans délai configuré) | ✅ |
| Approuver les demandes de rééquilibrage     | ✅ |
| Configurer les taux de ristourne            | ✅ |
| Générer les rapports financiers             | ✅ |
| Gérer l'abonnement (renouvellement, upgrade) | ✅ |
| Configurer les alertes                      | ✅ |

### 5.3 Contrôleur (`controleur`)

**Profil :** Superviseur terrain, manager intermédiaire  
**Périmètre :** Stands qui lui sont assignés, selon permissions du gestionnaire

| Fonctionnalité                                  | Accès           |
|-------------------------------------------------|-----------------|
| Tableau de bord contrôleur                      | ✅ |
| Voir les stands assignés                        | ✅ |
| Voir les opérations des agents sous sa supervision | ✅ |
| Gérer les agents (si permission accordée)       | Configurable |
| Approuver rééquilibrages (si permission)        | Configurable |
| Modifier opérations (si permission)             | Configurable |
| Voir rapports (si permission)                   | Configurable |
| Voir tous les stands (si permission)            | Configurable |
| Gérer ristournes (si permission)               | Configurable |

**Permissions configurables par le gestionnaire :**
- Gérer les agents
- Gérer les stands
- Approuver les rééquilibrages
- Modifier les opérations
- Voir les rapports financiers
- Initialiser les soldes
- Voir tous les stands

### 5.4 Agent (`agent`)

**Profil :** Opérateur de caisse sur le terrain  
**Périmètre :** Son stand assigné uniquement

| Fonctionnalité                              | Accès |
|---------------------------------------------|-------|
| Tableau de bord agent (soldes de son stand) | ✅ |
| Saisir une opération (dépôt / retrait / crédit forfait) | ✅ |
| Voir l'historique de ses opérations         | ✅ |
| Faire une demande de rééquilibrage          | ✅ |
| Voir le statut de ses demandes              | ✅ |

---

## 6. FONCTIONNALITÉS DÉTAILLÉES

### 6.1 Module Authentification

#### 6.1.1 Inscription (Gestionnaire)
- Formulaire : Prénom, Nom, Email, Téléphone, Mot de passe, Nom d'entreprise, Description
- Envoi d'un email de vérification Firebase
- Période d'essai gratuit de **30 jours** déclenchée à la vérification de l'email
- Validation : email unique, format téléphone béninois (+229)

#### 6.1.2 Connexion
- Authentification email/mot de passe via Firebase Auth
- Domaines autorisés : `sikaflow.org`, `sikaflow-c8869.web.app`, `localhost`
- Routage automatique vers le dashboard adapté au rôle
- Gestion du premier login (mot de passe provisoire → forcer le changement)

#### 6.1.3 Réinitialisation de mot de passe
- Envoi d'un email Firebase de réinitialisation
- Formulaire dédié accessible depuis la page de connexion

#### 6.1.4 Invitation de membres
- Le gestionnaire invite agents et contrôleurs par email
- Génération d'un mot de passe provisoire (envoyé par email)
- Activation à la première connexion (changement de mot de passe obligatoire)

---

### 6.2 Module Gestion des Stands

Un **stand** représente un point de vente physique (kiosque, boutique).

#### Données d'un stand
- Nom et localisation
- Agent(s) affecté(s) (historique des affectations)
- SIM Cards (MTN, Moov, Celtiis) avec numéro et solde
- Solde espèces (caisse physique)
- Statut (actif / inactif)
- Limite d'alerte de solde bas
- Délai de modification des opérations (minutes)

#### Fonctionnalités
- Création, modification, désactivation d'un stand
- Initialisation des soldes de départ (espèces + chaque SIM)
- Affectation/désaffectation d'un agent
- Historique des agents affectés
- Visualisation en temps réel des soldes

#### Règles métier
- Un agent ne peut être affecté qu'à un seul stand à la fois
- La désaffectation d'un agent libère le stand (sans le désactiver)
- Un stand inactif n'accepte plus de nouvelles opérations

---

### 6.3 Module Saisie des Opérations

#### Types d'opérations
| Code             | Libellé        | Impact Espèces | Impact SIM  |
|------------------|----------------|----------------|-------------|
| `depot`          | Dépôt          | ↑ (+ montant)  | ↓ (- montant) |
| `retrait`        | Retrait        | ↓ (- montant)  | ↑ (+ montant) |
| `credit_forfait` | Crédit forfait | ↑ (+ montant)  | ↓ (- montant) |

#### Modes de saisie
- **Détail** : Saisie avec numéro client, nom client, opérateur, montant
- **Synthèse** : Saisie agrégée (total par opérateur pour la journée)

#### Règles de saisie
- Sélection de l'opérateur (MTN / Moov / Celtiis)
- Validation : montant > 0, opérateur actif sur le stand
- Calcul automatique de la ristourne à la saisie
- Mise à jour immédiate des soldes (espèces + SIM concernée)
- Timestamp automatique (serveur)

#### Modification d'opération
- Délai configurable par le gestionnaire (ex : 30 minutes)
- Champ motif de modification obligatoire
- Historique des modifications (qui, quand, motif)
- Seul le gestionnaire ou contrôleur autorisé peut modifier

---

### 6.4 Module Alertes

#### Déclencheurs d'alertes
| Type d'alerte              | Description                                    |
|----------------------------|------------------------------------------------|
| `solde_sim_bas`            | Solde SIM < seuil configuré                    |
| `solde_especes_bas`        | Caisse espèces < seuil configuré               |
| `solde_sim_eleve`          | Solde SIM > seuil haut (risque de blocage)     |
| `inactivite_agent`         | Aucune opération depuis X heures               |
| `demande_reequilibrage`    | Agent a soumis une demande                     |

#### Fonctionnalités
- Configuration des seuils par stand
- Visualisation des alertes non lues (badge)
- Marquage comme lue (individuel ou tout marquer)
- Historique complet des alertes

---

### 6.5 Module Rééquilibrage

Le rééquilibrage consiste à transférer des liquidités (espèces ou SIM) entre stands ou depuis le siège.

#### Flux
1. **Agent** : Constate un déséquilibre → soumet une demande (montant, type, motif)
2. **Gestionnaire / Contrôleur** : Reçoit notification → examine la demande
3. **Décision** : Approuve (avec montant validé) ou rejette (avec motif)
4. **Mise à jour** : Soldes ajustés automatiquement si approuvée

#### Statuts d'une demande
- `en_attente` → `approuvee` ou `rejetee`

---

### 6.6 Module Ristournes

La **ristourne** est la commission versée à l'agent pour chaque opération réalisée.

#### Calcul
- Taux configuré par le gestionnaire (% du montant)
- Différentiation possible par opérateur et par type d'opération
- Calcul automatique à chaque saisie (`ristourneCalculee = montant × taux`)
- Cumul journalier / mensuel par agent

#### Fonctionnalités
- Configuration des taux par le gestionnaire
- Tableau de synthèse des ristournes par agent et par période
- Export possible en rapport

---

### 6.7 Module Rapports

#### Rapports disponibles
| Rapport                | Description                                     |
|------------------------|-------------------------------------------------|
| Rapport journalier     | Toutes les opérations du jour, par stand        |
| Rapport par période    | Sélection de date de début et de fin            |
| Rapport par agent      | Opérations d'un agent spécifique                |
| Rapport par opérateur  | Volumes MTN / Moov / Celtiis                    |
| Rapport ristournes     | Commissions dues par agent et par période       |
| État des soldes        | Snapshot instantané de tous les stands          |

#### Indicateurs clés (KPI)
- Total dépôts / retraits / crédits forfaits
- Volume total traité (FCFA)
- Nombre d'opérations
- Solde net espèces / SIM par stand
- Ristournes calculées
- Taux d'activité des agents

---

### 6.8 Module Super Admin

#### Tableau de bord global
- Nombre total d'entreprises (actives / en essai / suspendues)
- Nombre total d'utilisateurs
- Revenus mensuels (abonnements actifs)
- Entreprises créées ce mois

#### Gestion des entreprises
- Liste paginée avec recherche et filtres
- Détail d'une entreprise (membres, stands, abonnement)
- Activation / suspension manuelle d'un compte
- Historique des abonnements

#### Configuration des plans
- Interface de modification des plans tarifaires
- Activation/désactivation d'un plan
- Modification des prix, features, limites de stands
- Configuration globale (durée d'essai, remise annuelle, message promo)

---

### 6.9 Module Landing Page

Page marketing publique accessible sans authentification.

#### Sections
- **Hero** : Accroche, CTA "Commencer Gratuitement"
- **Statistiques** : Chiffres clés de la plateforme
- **Fonctionnalités** : Présentation des 6 fonctionnalités principales
- **Comment ça marche** : Étapes d'onboarding (3 étapes)
- **Rôles** : Explication des 4 profils utilisateurs
- **Tarifs** : Plans Solo / Pro / Entreprise (chargés depuis Firestore)
- **Opérateurs** : MTN, Moov, Celtiis
- **Témoignages** : Avis clients
- **CTA** : Appel à l'action final
- **Footer** : Liens, contact, mentions légales, lien Espace Admin

---

## 7. ARCHITECTURE TECHNIQUE

### 7.1 Stack technologique

| Couche           | Technologie                        | Version    |
|------------------|------------------------------------|------------|
| Framework mobile | Flutter                            | 3.35.4     |
| Langage          | Dart                               | 3.9.2      |
| State management | Provider                           | 6.1.5+1    |
| Base de données  | Cloud Firestore                    | 5.4.3      |
| Authentification | Firebase Auth                      | 5.3.1      |
| Stockage fichiers| Firebase Storage                   | 12.3.2     |
| Hébergement web  | Firebase Hosting                   | —          |
| Paiement         | FedaPay REST API (Live)            | v1         |
| Charts           | fl_chart                           | 0.69.0     |
| HTTP Client      | http                               | 1.5.0      |
| Localisation     | intl (fr_FR)                       | 0.19.0     |
| UUID             | uuid                               | 4.5.1      |
| Web Views        | webview_flutter                    | 4.13.0     |

### 7.2 Architecture applicative

```
┌─────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                  │
│  LandingPage │ LoginScreen │ Dashboards (4 rôles)       │
│  Screens: Auth / Admin / Gestionnaire / Agent / Contrôleur │
└────────────────────────┬────────────────────────────────┘
                         │ Provider (ChangeNotifier)
┌────────────────────────▼────────────────────────────────┐
│                  COUCHE ÉTAT / LOGIQUE                  │
│              AppProvider (ChangeNotifier)               │
│  État: utilisateur, entreprise, stands, opérations,     │
│  alertes, membres, abonnements, plans config            │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                   COUCHE SERVICES                       │
│  FirestoreService │ FedaPayService │ AuthService        │
│  ConfigAbonnementService                                │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                     FIREBASE                            │
│  Firestore (NoSQL) │ Auth │ Hosting │ Storage           │
└─────────────────────────────────────────────────────────┘
```

### 7.3 Architecture Firebase (Firestore)

Collections principales :
```
firestore/
├── users/              {uid}/   → profils utilisateurs
├── entreprises/        {id}/    → données entreprises
├── stands/             {id}/    → points de vente
├── operations/         {id}/    → transactions
├── alertes/            {id}/    → alertes système
├── demandes_reequilibrage/ {id}/ → demandes de rééquilibrage
├── taux_ristourne/     {id}/    → taux de commission
├── abonnements/        {id}/    → historique abonnements
└── config_abonnement/
    ├── plans           → liste des plans tarifaires
    └── global          → configuration globale (essai, remises)
```

### 7.4 Initialisation Firebase (architecture "Landing First")

```
main() → await Firebase.initializeApp() → runApp(SikaFlowApp)
                                                    │
                              ChangeNotifierProvider(create: AppProvider()..initialiser())
                                                    │
                              AppRouter: LandingPage (si non connecté)
                                        AdminDashboard / GestionnaireDashboard / etc. (si connecté)
```

**Principe** : Firebase est initialisé *avant* `runApp()` avec `await`, garantissant que l'auth est disponible dès le premier rendu. La LandingPage est statique (pas d'appels Firestore), assurant un affichage immédiat.

---

## 8. MODÈLE DE DONNÉES

### 8.1 Collection `users`

| Champ                   | Type      | Description                          |
|-------------------------|-----------|--------------------------------------|
| `id`                    | String    | UID Firebase Auth                    |
| `prenom`                | String    | Prénom                               |
| `nom`                   | String    | Nom                                  |
| `email`                 | String?   | Email                                |
| `telephone`             | String    | Numéro de téléphone                  |
| `role`                  | String    | super_admin / gestionnaire / agent / controleur |
| `entreprise_id`         | String?   | ID de l'entreprise (null pour super_admin) |
| `stand_id`              | String?   | Stand actuel (agents uniquement)     |
| `date_creation`         | Timestamp | Date de création du compte           |
| `date_affectation_stand`| Timestamp?| Date d'affectation au stand courant  |
| `mot_de_passe_provisoire`| Bool     | Premier login requis                 |
| `actif`                 | Bool      | Compte actif                         |
| `email_verifie`         | Bool      | Email vérifié                        |
| `permissions`           | List<String> | Permissions contrôleur            |

### 8.2 Collection `entreprises`

| Champ               | Type      | Description                               |
|---------------------|-----------|-------------------------------------------|
| `id`                | String    | ID document Firestore                     |
| `nom`               | String    | Nom de l'entreprise                       |
| `description`       | String?   | Description                               |
| `gestionnaire_id`   | String    | UID du gestionnaire principal             |
| `date_creation`     | Timestamp | Date d'inscription                        |
| `statut`            | String    | en_attente / essai / actif / suspendu     |
| `fin_essai`         | Timestamp | Date de fin de la période d'essai         |
| `limite_activation` | Timestamp | Délai max pour vérifier l'email           |
| `abonnement_actif`  | String?   | ID de l'abonnement en cours               |

### 8.3 Collection `stands`

| Champ              | Type      | Description                                |
|--------------------|-----------|---------------------------------------------|
| `id`               | String    | ID document                                 |
| `nom`              | String    | Nom du stand                                |
| `localisation`     | String?   | Adresse / description de l'emplacement      |
| `entreprise_id`    | String    | ID entreprise propriétaire                  |
| `agent_id`         | String?   | Agent actuellement affecté                  |
| `actif`            | Bool      | Stand actif                                 |
| `solde_especes`    | Double    | Solde caisse physique (FCFA)               |
| `sims`             | List      | Liste des SIM (opérateur, numéro, solde)   |
| `seuil_alerte`     | Double    | Seuil de déclenchement d'alerte (FCFA)     |
| `delai_modification`| Int      | Délai max de modification d'opération (min) |
| `historique_affectations` | List | Historique des agents affectés          |

### 8.4 Collection `operations`

| Champ              | Type      | Description                             |
|--------------------|-----------|------------------------------------------|
| `id`               | String    | ID document                              |
| `stand_id`         | String    | Stand concerné                           |
| `stand_nom`        | String    | Nom du stand (dénormalisé)               |
| `agent_id`         | String    | Agent ayant réalisé l'opération          |
| `agent_nom`        | String    | Nom de l'agent (dénormalisé)             |
| `entreprise_id`    | String    | Entreprise propriétaire                  |
| `operateur`        | String    | MTN / Moov / Celtiis                     |
| `type_operation`   | String    | depot / retrait / credit_forfait         |
| `montant`          | Double    | Montant en FCFA                          |
| `ristourne_calculee`| Double   | Commission calculée (FCFA)               |
| `numero_client`    | String?   | Numéro mobile du client                  |
| `nom_client`       | String?   | Nom du client                            |
| `date_heure`       | Timestamp | Horodatage                               |
| `modifiable`       | Bool      | Dans le délai de modification            |
| `modifie`          | Bool      | A été modifié                            |
| `motif_modification`| String?  | Motif de la modification                 |
| `date_modification`| Timestamp?| Date de la modification                  |
| `modifie_par`      | String?   | UID du modificateur                      |
| `mode_saisie`      | String    | detail / synthese                        |

---

## 9. MODÈLE ÉCONOMIQUE ET ABONNEMENTS

### 9.1 Plans tarifaires

| Plan           | Nb de stands    | Prix mensuel | Prix annuel (−20%) | Populaire |
|----------------|-----------------|--------------|---------------------|-----------|
| **Solo**       | 1 stand         | 1 200 F CFA  | 11 520 F CFA/an     | —         |
| **Pro**        | 2 à 5 stands    | 5 000 F CFA  | 48 000 F CFA/an     | ⭐         |
| **Entreprise** | 6 stands et +   | 10 000 F CFA | 96 000 F CFA/an     | —         |

### 9.2 Essai gratuit

- Durée : **30 jours** à partir de la vérification de l'email
- Limite : 1 stand pendant la période d'essai
- Pas de carte bancaire requise pour démarrer
- Délai de vérification d'email : 72 heures après inscription

### 9.3 Cycle de vie d'un compte

```
Inscription → en_attente (72h max pour vérifier l'email)
           → essai (30 jours, 1 stand)
           → actif (abonnement payant)
           → suspendu (abonnement expiré ou impayé)
```

### 9.4 Paiement — FedaPay

- **Intégration** : API REST FedaPay (Live) en FCFA
- **Mode** : Paiement par Mobile Money (MTN, Moov, Celtiis)
- **Flux** :
  1. Gestionnaire choisit un plan et une période (mensuel / annuel)
  2. SikaFlow crée une transaction FedaPay via l'API
  3. Redirection vers le checkout FedaPay (WebView in-app)
  4. Confirmation → activation de l'abonnement dans Firestore
- **Environnements** : Sandbox (tests) et Live (production)

### 9.5 Upgrade / Downgrade

- L'upgrade est possible à tout moment (passage à un plan supérieur)
- Le downgrade prend effet à l'échéance de la période en cours
- L'Super Admin peut activer, suspendre ou modifier un abonnement manuellement

---

## 10. INTERFACES UTILISATEUR

### 10.1 Thème visuel

| Élément          | Valeur                               |
|------------------|--------------------------------------|
| Thème            | Dark (mode sombre)                   |
| Couleur primaire | `#0D1B3E` (bleu nuit)               |
| Accent           | `#FF6B35` (orange vif)              |
| Succès           | `#4CAF50` (vert)                    |
| Erreur           | `#F44336` (rouge)                   |
| Fond             | `#0A0E1A` (noir bleuté)             |
| Cartes           | `#111827` (gris foncé)              |
| Texte secondaire | `#6B7280` (gris moyen)              |
| Police           | Material Design (Roboto par défaut) |

### 10.2 Navigation par rôle

```
Super Admin     → AdminDashboard (Tabs: Dashboard | Entreprises | Abonnements | Plans)
Gestionnaire    → GestionnaireDashboard (Tabs: Accueil | Stands | Membres | Ops | Rapports)
Agent           → AgentDashboard (Saisie opération | Historique | Rééquilibrage)
Contrôleur      → ControleurDashboard (Vue stands assignés | Opérations | Alertes)
```

### 10.3 Responsive design

- **Mobile Android** : Cible principale, interface optimisée pour écrans 360-414 dp
- **Web / tablette** : Progressive Web App, layout adaptatif (isWide breakpoint 768px)
- **SafeArea** : Gestion des encoches et barres système sur toutes les vues

---

## 11. SÉCURITÉ ET CONFORMITÉ

### 11.1 Authentification

- Firebase Authentication (email/password)
- Sessions persistantes avec jeton Firebase (rafraîchissement automatique)
- Vérification obligatoire de l'email avant accès
- Politique de mot de passe : minimum 8 caractères
- Réinitialisation sécurisée par email

### 11.2 Autorisation

- Règles Firestore par collection (utilisateur peut lire/écrire uniquement ses données)
- Isolation multi-tenant : chaque entreprise ne voit que ses propres données via `entreprise_id`
- Validation côté client ET règles Firestore côté serveur

### 11.3 Données financières

- Toutes les communications chiffrées TLS/HTTPS
- Aucune donnée bancaire stockée dans Firestore (paiements gérés exclusivement par FedaPay)
- Logs d'audit pour toutes les modifications d'opérations

### 11.4 Domaines autorisés Firebase Auth

- `localhost` (développement)
- `sikaflow-c8869.firebaseapp.com`
- `sikaflow-c8869.web.app`
- `sikaflow.org`
- `www.sikaflow.org`

---

## 12. PERFORMANCES ET CONTRAINTES

### 12.1 Contraintes réseau (Bénin)

- L'application doit fonctionner correctement sur des connexions 3G/4G intermittentes
- La LandingPage est 100 % statique (aucun appel réseau avant connexion)
- Les opérations critiques (saisie) ont un mode offline partiel avec sync ultérieure

### 12.2 Contraintes de performance

| Indicateur                          | Cible       |
|-------------------------------------|-------------|
| Time to Interactive (LandingPage)   | < 2 secondes |
| Sync Firestore (temps réel)         | < 1 seconde  |
| Taille bundle web (Flutter Web)     | < 5 MB compressé |
| Temps de build web release          | < 60 secondes |

### 12.3 Scalabilité

- Architecture multi-tenant : isolation par `entreprise_id` dans chaque collection
- Firestore supporte nativement la montée en charge horizontale
- Pas de limitation technique sur le nombre d'entreprises, stands ou opérations

---

## 13. DÉPLOIEMENT ET INFRASTRUCTURE

### 13.1 Hébergement web

- **Firebase Hosting** : `https://sikaflow.org` (domaine personnalisé)
- CDN mondial Firebase (Cloudflare en backend)
- HTTPS automatique (Let's Encrypt)
- Déploiement CI : `flutter build web --release && firebase deploy --only hosting`

### 13.2 Script post-build

Après chaque build Flutter Web, le script `fix_bootstrap.py` :
- Supprime les entrées vides du tableau `builds` dans `flutter_bootstrap.js`
- Active `useLocalCanvasKit: true` (évite le chargement de gstatic.com)

### 13.3 Application Android

- **Package** : `com.mobilemoneycontrol.control`
- **Target SDK** : Android API 35 (Android 15)
- **Build** : `flutter build apk --release` ou `flutter build appbundle --release`
- **Distribution** : Google Play Store (prévu V2) ou distribution directe (APK)

### 13.4 Branches Git

| Branche | Usage                              |
|---------|------------------------------------|
| `main`  | Production (déploiement auto)      |
| `dev`   | Développement et tests (à créer)   |

**Dépôt :** https://github.com/Augustin0527/SikaFlow

---

## 14. JALONS ET LIVRABLES

### Phase 1 — Fondations (✅ Livrée)
- Architecture Flutter + Firebase
- Authentification (inscription, connexion, vérification email)
- Landing page marketing
- Modèles de données (7 entités)
- Thème visuel dark

### Phase 2 — Cœur métier (✅ Livrée)
- Gestion des stands et des SIM
- Saisie des opérations (3 types, 2 modes)
- Tableau de bord gestionnaire et agent
- Système d'alertes
- Demandes de rééquilibrage
- Calcul des ristournes

### Phase 3 — Monétisation (✅ Livrée)
- Intégration FedaPay (paiement Mobile Money)
- 3 plans tarifaires (Solo, Pro, Entreprise)
- Essai gratuit 30 jours
- Super Admin avec gestion des abonnements

### Phase 4 — Rapports et supervision (✅ Livrée)
- Rapports financiers consolidés (fl_chart)
- Dashboard contrôleur avec permissions granulaires
- Administration Super Admin complète

### Phase 5 — Production (✅ Livrée)
- Déploiement Firebase Hosting (sikaflow.org)
- Correction domaines autorisés Firebase Auth
- Architecture Landing-First (Firebase en arrière-plan)
- Nom de l'app Android : "SikaFlow"

### Phase 6 — Évolutions (🔄 Prévue)
- Application iOS
- Notifications push (Firebase Cloud Messaging)
- Export Excel/PDF des rapports
- API REST pour intégrations tierces
- Application mobile Google Play Store
- Module comptabilité avancée

---

## 15. GLOSSAIRE

| Terme              | Définition                                                       |
|--------------------|------------------------------------------------------------------|
| **Stand**          | Point de vente physique Mobile Money (kiosque, agence)          |
| **Agent**          | Opérateur de caisse affecté à un stand                          |
| **Gestionnaire**   | Propriétaire ou directeur de l'agence                           |
| **Contrôleur**     | Superviseur intermédiaire avec permissions configurables        |
| **Super Admin**    | Administrateur global de la plateforme SikaFlow                 |
| **SIM Card**       | Carte SIM opérateur (MTN / Moov / Celtiis) d'un stand          |
| **Dépôt**          | Client remet des espèces, reçoit crédit Mobile Money           |
| **Retrait**        | Client remet crédit Mobile Money, reçoit espèces               |
| **Crédit forfait** | Achat de forfait (data, appels) contre espèces                  |
| **Ristourne**      | Commission versée à l'agent sur chaque opération                |
| **Rééquilibrage**  | Transfert de liquidités (espèces ou SIM) vers un stand         |
| **Essai**          | Période gratuite de 30 jours pour tester la plateforme         |
| **SaaS**           | Software as a Service — abonnement mensuel/annuel               |
| **FedaPay**        | Passerelle de paiement Mobile Money en Afrique de l'Ouest       |
| **FCFA**           | Franc CFA — monnaie utilisée au Bénin                          |
| **Firestore**      | Base de données NoSQL temps réel de Firebase (Google)           |
| **Multi-tenant**   | Architecture où plusieurs entreprises partagent la même app    |

---

*Document rédigé sur la base du code source de l'application SikaFlow v1.0.0*  
*© 2025 SikaFlow — GFPEANC — Cotonou, Bénin*  
*Contact : contact@sikaflow.org*
