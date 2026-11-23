# Spécification — demandes d’intégration (Maison)

Ce document formalise les demandes métier exprimées pour l’interface de consultation (ex: `maison.smk.digital`) afin de les intégrer dans une autre partie de l’application.

## 1) Objectif produit

Rendre les rapports réseau :

- plus lisibles (moins de scroll),
- actionnables (savoir quoi corriger immédiatement),
- et traçables (version visible pour confirmer le déploiement actif).

## 2) Périmètre fonctionnel demandé

### 2.1 Fenêtre de données

- Conserver les rapports sur une **fenêtre glissante de 7 jours**.
- Pas de conservation au-delà dans la vue standard.

### 2.2 Tableau paginé (interface)

- Affichage principal sous forme de **tableau paginé**.
- Pagination attendue :
  - **défaut = 20 lignes/page**
  - **maximum = 50 lignes/page**
- L’utilisateur doit pouvoir naviguer par page sans scroll long.

### 2.3 Qualité réseau : lisibilité des alertes

Pour chaque alerte qualité, afficher explicitement :

- le **nom du device** concerné,
- son **type** (`mobile` ou `fixed`),
- la **sévérité** (WARN/CRITICAL),
- et l’**action recommandée**.

### 2.4 Logique métier mobile vs fixe

Différencier le traitement :

- **Device mobile** (ex: MacBook, iPad, iPhone) :
  - si signal faible, action principale = **forcer une reconnexion** (déconnexion puis réassociation).
- **Device fixe** (ex: Refoss, prises, IoT fixes) :
  - si signal faible, action principale = **investigation infra** (couverture, AP, canal, interférences, positionnement).

### 2.5 Plan de correction explicite

Ajouter une section dédiée qui synthétise les actions à mener, par device.

Exemples de labels d’action :

- `FORCER_RECONNEXION`
- `INVESTIGATION_FIXE`
- `INVESTIGATION_FIXE_PRIORITAIRE`

### 2.6 Notifications Telegram

Les notifications doivent reprendre les mêmes informations que le rapport :

- nom du device,
- type `[mobile]` ou `[fixed]`,
- RSSI + sévérité,
- action recommandée,
- version visible.

### 2.7 Version visible (vérification de déploiement)

Afficher deux niveaux de version :

- `report_version` : version fonctionnelle du script/logique,
- `deploy_version` : compteur incrémenté à chaque déploiement.

Objectif : vérifier immédiatement si l’instance affichée est bien la dernière version déployée.

## 3) Contrat de rendu attendu (minimum)

## 3.1 Dans le rapport

Ligne de métadonnées visible :

```text
report_version=<x.y.z> deploy_version=<n> pagination_default=20 pagination_max=50
```

Section alertes qualité :

```text
Alertes qualite (device / type):
- MacBook-Mika [mobile] RSSI=-79 dBm (WARN, quality-poor-mobile)
```

Section plan de correction :

```text
Plan de correction (decision mobile/fixe):
- MacBook-Mika [mobile] -> action: FORCER_RECONNEXION (...)
- Refoss [fixed] -> action: INVESTIGATION_FIXE_PRIORITAIRE (...)
```

### 3.2 Dans Telegram

Message synthétique avec :

- versions (`report_version` + `deploy_version`),
- liste des alertes avec type et action,
- résumé des compteurs d’action.

## 4) Règles décisionnelles à conserver

- Si device `mobile` + qualité faible => orienter vers reconnexion.
- Si device `fixed` + qualité faible => orienter vers investigation radio/infra.
- La mobilité autorise un changement de borne plus souple pour les mobiles que pour les fixes.

## 5) Critères d’acceptation (UAT)

1. Le tableau est paginé en 20 par défaut, et refuse > 50.
2. La fenêtre affichée ne dépasse pas 7 jours glissants.
3. Une alerte qualité indique toujours `device + type mobile/fixed`.
4. Le plan de correction indique clairement l’action à entreprendre.
5. La notification Telegram contient les mêmes infos critiques.
6. `report_version` et `deploy_version` sont visibles et vérifiables.

## 6) Notes d’intégration

- Cette spec est volontairement orientée **métier/UI**.
- L’implémentation script actuelle peut être utilisée comme source, mais l’autre partie peut adapter le rendu tant que les critères ci-dessus restent vrais.
