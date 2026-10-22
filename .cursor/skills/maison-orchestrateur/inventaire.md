# Inventaire clients (Omada × Freebox × HA)

Noms réels connus au 2026-10-22. Vérifier en live.

| IP | Nom réel | Notes |
|---|---|---|
| .20 | Reolink terrasse Duo 2 | Fixe |
| .21 | Reolink sonnette doorbell | Fixe ; lock 225 OK |
| .22 | Reolink cuisine | |
| .23 | Reolink salon | |
| .27 | Player POP (CPL) | Garder ; couper le Wi-Fi `.15` |
| .31 | P110 box | |
| .32 | P110 ordi | |
| .40 | EAP610 Outdoor | Fixe |
| .41 | Passerelle Legrand | |
| .42 | Refoss EM06 | Plan : déplacer `.33` pour libérer switch `.42` |
| .43 | Brother BRW (imprimante) | Occupe la cible EAP720 |
| .51–.53 | MOES Matter bureau (lwip0) | |
| .60 | Home Assistant Green | Figée |
| .70 | Tablette entrée | Souvent Wi-Fi Freebox, pas Omada |
| .73 | Switch SG2210P | Plan `.42` |
| .80 | Shelly Mini G4 bouton portail | |
| .81 | DW2 | |
| .88 | Dreame | DHCP |
| .89 | Apple « Cuisine » | Pas Shelly ; Tado = Matter Thread |
| .91 | EAP720 Salon | DHCP ; collision plan bouton `.91` |
| .94 | iPad | |
| .106 / .154 | devolo Magic (CPL) | Switch port 3 |
| .111 | EAP225 Outdoor | Plan `.44` |
| .135 | NAS LAN1 | Plan dernière : `.61` |
| .143 | iPhone | |
| .150 | NAS LAN2 SPAN | Pas de réservation |
| .155 | Shelly G3 lumière cuisine | Sticky 610 fréquent, viser salon |
| .172 | Portail — lecteur empreintes | Shelly G3 `S3SW-001X16EU` |
| .198 | Reolink jardin/piscine (Quectel) | HA `camera.camera_jardin_piscine_fluide` |

Omada « Chili 1 G3 » = Shelly Gen3 (croiser l’IP).
