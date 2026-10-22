# Maison

Worker Cursor sur le Synology DS720+. Unique agent visible : **Maison**. Les spécialistes (mesure, Omada, Freebox, HA, ntopng) restent internes.

## Machine à choisir

Dans Cursor (app, iPhone, [cursor.com/agents](https://cursor.com/agents)) : dépôt `Mika-SMK/maison`, exécution **My Machines → maison**.

Un agent **Cloud** n’est pas dans le LAN. Il ne doit ni installer Omada/ntopng, ni conclure qu’ils manquent.

## Services déjà en place (NAS)

| Service | Où | Test depuis le worker |
|---|---|---|
| Omada 5.15 | Docker host network, `:8043` | `curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:8043/` |
| ntopng 7 | Docker host network, `:3000` | `curl -sI http://127.0.0.1:3000/` (302 = OK) |
| Freebox | `192.168.1.254` | `curl -s http://192.168.1.254/api_version` |
| Home Assistant | `192.168.1.60:8123` | souvent 401 sans jeton |

Le worker est en `network_mode: host`. `docker ps` **dans** le worker ne voit pas ces conteneurs (pas de socket Docker). Ce n’est pas une preuve d’absence.

Ne pas lancer de second stack. Omada 6 (`:latest`) ne tourne pas sur ce NAS (pas d’AVX).

## Secrets

Fichier `.env` **sur le NAS**, à partir de `.env.example`. Jamais dans git.

## Docs

- `AGENTS.md` — identité et interdits
- `docs/acces-distant.md` — comment viser la machine maison
- `.cursor/skills/` — playbooks internes
