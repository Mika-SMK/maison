---
name: audit-reseau-maison
description: >-
  Internal measurement playbook for Maison (Omada, Freebox, ntopng). Not user-facing.
disable-model-invocation: true
---

# Playbook de mesure (interne)

Lecture seule. HTTP via `relais-lan`. Noms : `../maison-orchestrateur/inventaire.md`.

## Topologie

- Routeur / DHCP / NAT / DNS : Freebox Pop `192.168.1.254` (API v8/v16). Pas de 2e NAT.
- Omada 5.15 sur NAS (pas v6) : `omadacId` `aa6634b230b16aea9c6408b02d350877`, site `6a85b03b6ecae9406b843d36`. L2 only.
- Switch SG2210P `.73` : plafond cuivre 1 Gbit.
- HA Green `.60:8123`.
- SSID `Freebox-23FBC4` souvent encore sur la box **et** Omada.

| Borne | MAC | IP | Lien |
|---|---|---|---|
| EAP720 Salon | `C0-3A-55-EE-46-A4` | DHCP `.91` | Ethernet **14** ; mesh **15** interdit |
| EAP610 Outdoor | `50-3D-D1-6A-26-22` | `.40` | Ethernet 14 ; 5 GHz ch **100** |
| EAP225 Outdoor | `60-15-6F-5B-F3-6A` | `.111` | Mesh 15 ; 2.4 ch **1** |

Canaux 2.4 : 225 = **1**, salon = **6 @ 20 MHz**, 610 = **11**.

## Auth

Env NAS uniquement. Omada : `AccessToken={tok}`. Freebox : `settings` souvent false → writes 403. OpenAPI radios/EAP souvent 404 — ne pas insister.

## Mesures

- RSSI : OK ≥ −65 ; faible −66–−75 ; souffrance < −75.
- `detailStatus` 14 / 15 / 30 (heartbeat missed).
- Salon switch port 5, 610 port 6. PoE ≠ data.
- DHCP pool souvent `.2–.200` (cible `.100–.199`). Fixes : cams `.20–.23`, P110 `.31/.32`, 610 `.40`, Legrand `.41`, Refoss `.42`, ampoules `.51–.53`, HA `.60`, tablette `.70`, Shelly `.80`, DW2 `.81`.
- WAN 5 Gbit/900 Mbit souvent vide ; congestion = double SSID, ch 11, sticky IoT, mesh, heartbeat.

Ne pas appliquer de changement ici.
