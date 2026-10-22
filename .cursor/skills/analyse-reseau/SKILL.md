---
name: analyse-reseau
description: >-
  Internal read-only home LAN analysis (Omada, Freebox, ntopng, names). Not user-facing.
disable-model-invocation: true
---

# Analyse réseau (interne)

Lecture uniquement. Français. Aucun secret en clair. HTTP via `relais-lan`. Playbook : `audit-reseau-maison`.

## Sources

1. Omada : devices, clients (RSSI, AP, bande), `detailStatus` 14 Ethernet / 15 mesh / 30 heartbeat missed.
2. Freebox : connection, DHCP fixe vs pool, Wi-Fi box ON/OFF, LAN hosts.
3. ntopng : info, hosts, talkers — congestion LAN vs WAN.
4. Noms : `maison-orchestrateur/inventaire.md`.

Seuils RSSI : OK ≥ −65 ; faible −66 à −75 ; souffrance < −75.

Canaux 2.4 cibles : EAP225 **1**, salon **6 @ 20 MHz**, 610 **11**. 610 5 GHz **ch 100** (ne pas proposer de le changer).

Anomalies fréquentes : SSID Freebox encore ON ; salon et 610 tous deux ch 11 ; lumière cuisine `.155` sticky 610 ; tablette `.70` hors Omada ; Player POP dual IP ; EAP720 DHCP `.91`.

## Interdit

Aucun POST/PATCH/PUT métier, reboot, rename, plan d’adressage appliqué.

Retour au parent (pas à l’utilisateur) : verdict, bornes, souffrance, DHCP, ntopng, accès, max 5 corrections proposées avec cible `omada|freebox|ha|ntopng`.
