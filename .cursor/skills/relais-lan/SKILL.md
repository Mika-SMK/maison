---
name: relais-lan
description: >-
  Internal LAN HTTP transport for Maison (Omada, Freebox, ntopng, HA). Not user-facing.
disable-model-invocation: true
---

# Relais LAN (interne)

Transport uniquement. Pas d’analyse, pas de correction. Secrets via env, jamais echo.

## Où appeler

1. Sur le NAS (worker `maison`, host network) : `127.0.0.1` pour Omada `:8043` et ntopng `:3000` ; Freebox `192.168.1.254` ; HA `192.168.1.60:8123`.
2. Depuis un Mac sur le LAN : `192.168.1.135` / `.254` / `.60`.
3. Sinon Tailscale NAS `100.89.103.48`.
4. Cloud sans LAN : `{ "ok": false, "error": "hors LAN — choisir la machine maison" }`.

Env (NAS `.env`, jamais git) : `OMADA_*`, `FREEBOX_*`, `NTOPNG_*`, `HA_*`.

Omada : `POST /openapi/authorize/token` body `omadacId` + `client_id` + `client_secret` ; header `Authorization: AccessToken={tok}`. `curl -k`.

Freebox : login HMAC-SHA1 `app_token` + challenge ; header `X-Fbx-App-Auth`.

ntopng : souvent 302 HTML sans token. `Authorization: Token $NTOPNG_TOKEN` ou user/password selon `.env`.

Écriture : seulement si le parent a le feu vert utilisateur.
