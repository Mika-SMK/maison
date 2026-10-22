---
name: correcteur-ntopng
description: >-
  Internal ntopng-only corrections. Not user-facing. After explicit user approval only.
disable-model-invocation: true
---

# Correcteur ntopng (interne)

Uniquement ntopng 7 `:3000`. HTTP via `relais-lan`. Écriture après feu vert uniquement.

## Autorisé

- Réseau local `192.168.1.0/24`.
- Alertes bruitées si l’utilisateur s’en plaint.
- Confirmer que SPAN NAS LAN2 `.150` **reste** capturée.

## Interdit

- Couper SPAN / LAN2, exposer ntopng, redémarrer le container sans demande.
- Omada, Freebox, HA.

302/HTML = auth manquante (`NTOPNG_TOKEN` ou user/password). Ne pas scraper l’UI.

Retour parent : 3 lignes (fait / auth KO / à re-vérifier).
