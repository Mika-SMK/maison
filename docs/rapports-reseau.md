# Rapports reseau (scripts/probe-lan.sh)

Le script `scripts/probe-lan.sh` produit un rapport tabulaire pagine avec retention glissante sur 7 jours.

## Objectifs

- Limiter le scroll: affichage par pages (`--page`, `--page-size`).
- Garder uniquement l'historique utile: fenetre glissante de 7 jours.
- Clarifier les erreurs de qualite: statuts explicites et action proposee.
- Tenir compte de la mobilite des devices: regles differentes mobile vs fixe.

## Usage

```bash
scripts/probe-lan.sh \
  --devices-file docs/devices-sample.csv \
  --page 1 \
  --page-size 20
```

Options principales:

- `--devices-file <path>`: CSV device (voir format plus bas).
- `--page-size <n>`: nombre de lignes par page (defaut `20`, maximum `50`).
- `--report-dir <path>`: dossier de persistance (defaut: `.maison-reports`).
- `--auto-heal-mobile`: active la tentative de reconnexion automatique des mobiles en signal faible.
- `--mobile-disconnect-cmd <cmd>`: commande appelee avec `"<cmd> <mac> <name>"`.
- `--version`: affiche la version du script de rapport.

Chaque execution affiche aussi une ligne de version directement dans la sortie:

```text
report_version=2.1.0 pagination_default=20 pagination_max=50
```

## Format CSV devices

Colonnes attendues:

```csv
name,mac,rssi,ap,expected_ap,mobility
```

- `mobility` est optionnel: `mobile` ou `fixed`.
- Si `mobility` est vide, le script infere a partir du nom:
  - mobile: `macbook`, `iphone`, `ipad`, `tablet`, etc.
  - fixe: `refoss`, `prise`, `camera`, `shelly`, etc.

## Logique metier

### Association borne attendue

- Device **mobile** sur une borne differente de `expected_ap`:
  - evenement `mobility-allowed` (INFO), pas d'alerte bloquante.
- Device **fixe** sur une borne differente de `expected_ap`:
  - evenement `unexpected-ap` (WARN), action de verification.

### Qualite RSSI

- `>= -65`: `quality-good` (OK)
- `-66` a `-75`: `quality-fair` (INFO mobile / WARN fixe)
- `< -75`: `quality-poor` (WARN mobile / CRITICAL fixe)

Les statuts de qualite incluent maintenant le type de device:

- `quality-...-mobile`
- `quality-...-fixed`

Et un bloc dedie est affiche apres le tableau:

```text
Alertes qualite (device / type):
- MacBook [mobile] RSSI=-79 dBm (WARN)
```

### Auto-heal mobile

Pour un mobile en `quality-poor`, le script peut tenter une deconnexion:

- desactive par defaut (trace `reconnect-skipped`),
- active avec `--auto-heal-mobile`,
- execute la commande fournie par `--mobile-disconnect-cmd`.

## Codes de sortie

- `0`: pas d'erreur ni critique
- `1`: au moins une erreur (`ERROR`)
- `2`: au moins un evenement critique (`CRITICAL`)
