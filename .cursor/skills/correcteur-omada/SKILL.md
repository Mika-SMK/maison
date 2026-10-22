---
name: correcteur-omada
description: >-
  Internal Omada-only corrections. Not user-facing. After explicit user approval only.
disable-model-invocation: true
---

# Correcteur Omada (interne)

Uniquement Omada 5.15. HTTP via `relais-lan`. Écriture seulement après feu vert utilisateur (via le parent).

## Autorisé

- Canal / largeur 2.4 salon → **6 @ 20 MHz**.
- Rename client selon l’inventaire.
- Signaler un salon en mesh (15) ; ne pas brute-force un endpoint 404.

## Interdit

- 5 GHz EAP610 (ch 100).
- Omada 6, gateway Omada, 2e NAT, reboot AP sans phrase explicite.
- Freebox, HA, ntopng.

OpenAPI : `Authorization: AccessToken={tok}`. Radios/EAP souvent 404 : arrêter.

Retour parent : 3 lignes (fait / échec / à re-mesurer).
