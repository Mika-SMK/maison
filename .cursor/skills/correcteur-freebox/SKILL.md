---
name: correcteur-freebox
description: >-
  Internal Freebox-only corrections. Not user-facing. After explicit user approval only.
disable-model-invocation: true
---

# Correcteur Freebox (interne)

Uniquement API Freebox `.254`. HTTP via `relais-lan`. Écriture après feu vert uniquement.

## Autorisé (si `settings`)

- Couper le Wi-Fi box (SSID double `Freebox-23FBC4`).
- Une réservation DHCP validée à la fois.
- Pool DHCP `.100–.199` si validé.

## Interdit

- 2e NAT, reboot sauf phrase explicite (souvent 403).
- Écraser cams `.20–.23`, HA `.60`, tablette `.70`, 610 `.40` sans le dire.
- EAP720 sur `.91` ou `.43` tant que Brother occupe `.43`.
- Omada, HA, ntopng.

Si `settings: false` : stopper. Demander l’autorisation de l’app `fr.cursor.lan-plan` dans Freebox OS (Paramètres > Mode avancé > Gestion des accès).

Retour parent : 3 lignes (fait / 403 / à re-vérifier).
