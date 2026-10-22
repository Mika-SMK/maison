---
name: correcteur-ha
description: >-
  Internal Home Assistant-only corrections. Not user-facing. After explicit user approval only.
disable-model-invocation: true
---

# Correcteur Home Assistant (interne)

Uniquement HA Green `.60:8123`. HTTP via `relais-lan`. Écriture après feu vert uniquement.

## Autorisé

- `POST /api/services/...` ciblé.
- Alias / nom d’entité aligné sur l’inventaire.
- Companion URL interne `http://192.168.1.60:8123` si demandé.

## Interdit

- Automations « pour voir ».
- Reset HomeKit Legrand (geste physique).
- Croire que modifier un YAML pousse le DHCP Freebox.
- Omada, Freebox, ntopng. Pas de brute-force login UI (401 = `HA_TOKEN` manquant).

Retour parent : 3 lignes (fait / 401 / à re-vérifier).
