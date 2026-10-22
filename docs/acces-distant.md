# Accéder au réseau local depuis les vacances

Un worker Cursor tourne dans un conteneur sur le Synology. Il ouvre une connexion HTTPS sortante vers Cursor. Quand une tâche vise la machine `maison`, les commandes partent de ce conteneur, donc du réseau local : ntopng, Omada, Freebox.

Aucun port n'est ouvert sur la box. Le VPS n'entre pas dans ce montage. Tailscale non plus : il servirait seulement à ouvrir soi-même une page `192.168.x.x` dans un navigateur distant.

Ce dépôt ne contient pas d'application. Les secrets restent dans un fichier `.env` sur le NAS.

## Choisir où les commandes s'exécutent

Cursor ne détecte pas si tu es à la maison ou en voyage. Le choix se fait avant l'envoi, dans le menu sous le champ de saisie.

- **Local** : les commandes partent de l'ordinateur où Cursor est ouvert. À la maison, le Mac est déjà dans le LAN et joint les équipements directement. Le NAS n'est pas dans le chemin.
- **maison** : les commandes partent du conteneur. Le même choix est sur [cursor.com/agents](https://cursor.com/agents).

Le dire dans le message ne change pas la cible. Un chat déjà ouvert en Local reste sur le Mac. Pour passer par le NAS, ouvrir une tâche avec `maison` sélectionné.

Dans Réglages, Agents, l'environnement par défaut peut rester sur « dernier utilisé ». Après un envoi vers `maison`, la tâche suivante redémarre au même endroit. Vérifier le sélecteur avant d'envoyer.

Le worker n'est pas lié à une conversation. Chaque nouvelle tâche qui choisit `maison` l'utilise, depuis l'app, le téléphone ou cursor.com/agents.

## Ce que le conteneur peut faire

Être dans le LAN ouvre le chemin réseau. Ça ne crée pas de compte. Sans jeton, une API qui exige une authentification répond 401 ou 403. L'agent voit l'échec.

Les valeurs se posent dans `.env` sur le NAS, à partir de [`.env.example`](../.env.example). Ce fichier d'exemple ne contient que des noms. `.env` est ignoré par git.

- **ntopng** : `NTOPNG_URL`, et `NTOPNG_USER` / `NTOPNG_PASSWORD` si l'interface n'est pas ouverte sans authentification.
- **Omada** : `OMADA_URL`, plus le couple utilisateur/mot de passe ou le couple client API.
- **Freebox** : `FREEBOX_APP_ID` et `FREEBOX_APP_TOKEN`. Le premier appairage se fait à la maison, avec la validation sur la Freebox. Ensuite le conteneur réutilise ce jeton.

L'agent fait ce qu'un terminal du conteneur pourrait faire avec ces variables. Rien de plus. Le conteneur n'a pas de bureau : ntopng s'interroge en HTTP, pas en cliquant dans une page.

## 1. Dépôt git avec un remote

Le sélecteur n'affiche `maison` que si le dossier du worker a un remote git. Ce dépôt peut servir.

Créer un dépôt privé, puis depuis cette machine :

```bash
git remote add origin <url-du-depot-prive>
git push -u origin HEAD
```

Sur le NAS, le conteneur travaille dans une copie clonée, pas dans un dossier sans remote.

## 2. Conteneur sur le Synology

Dans Container Manager, créer un projet dont le conteneur est Debian, en réseau hôte, avec redémarrage automatique. DSM lui-même n'est pas un Linux standard : le CLI Cursor s'installe dans le conteneur.

Le réseau hôte laisse le conteneur joindre les IP du LAN. Sans cela, `NTOPNG_URL` et les autres adresses locales ne répondent pas.

Fichiers sur le NAS, hors git :

- `.env`, rempli à partir de l'exemple ;
- `start-worker.sh`, script ci-dessous ;
- un dossier `workspace` qui recevra le clone.

`docker-compose.yml` du projet :

```yaml
services:
  cursor-worker:
    image: debian:bookworm-slim
    network_mode: host
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - ./workspace:/workspace
      - ./start-worker.sh:/start-worker.sh:ro
    working_dir: /workspace
    command: ["bash", "/start-worker.sh"]
```

`start-worker.sh` :

```bash
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git bash
rm -rf /var/lib/apt/lists/*

curl https://cursor.com/install -fsS | bash
export PATH="$HOME/.local/bin:$PATH"

if [ ! -d /workspace/.git ]; then
  echo "Cloner le dépôt privé dans /workspace avant de laisser le worker démarrer."
  exit 1
fi

exec agent worker start \
  --name maison \
  --worker-dir /workspace \
  --api-key "$CURSOR_API_KEY"
```

Rendre le script exécutable (`chmod +x start-worker.sh`). `CURSOR_API_KEY` est une clé API personnelle, créée dans le dashboard Cursor, page API Keys. Une clé de compte de service ne démarre pas ce worker.

Cloner le dépôt privé dans `workspace` (avec un accès en lecture au remote), puis démarrer le projet. Le process doit rester lancé. Au redémarrage du NAS, Container Manager le relance.

Pour qu'un autre projet soit exécuté sur le NAS, le cloner à côté et ajouter un `--worker-dir` par dépôt dans la commande. Chaque dossier doit avoir son remote. Un dossier non déclaré reste traité en Local, sur le Mac.

## 3. Vérifier que les commandes partent du NAS

1. Contrôler que le conteneur tourne et que `agent worker` est le process principal.
2. Ouvrir [cursor.com/agents](https://cursor.com/agents).
3. Dans le menu qui choisit où l'agent s'exécute, sélectionner `maison` sous My Machines.
4. Envoyer : « Depuis quelle machine parles-tu ? Interroge ntopng et résume les hôtes. »

La sortie doit montrer le conteneur, et une réponse de ntopng (ou un 401 si le jeton manque). Une commande qui échoue parce que `192.168.x.x` est injoignable veut dire que la tâche est encore en Local, ou que le conteneur n'est pas en réseau hôte.

Si `maison` n'apparaît pas :

- le process `agent worker` tourne encore ;
- l'app Cursor et le CLI du conteneur utilisent le même compte ;
- `/workspace` a un remote git ;
- le NAS joint en HTTPS sortant `api2.cursor.sh`, `api2direct.cursor.sh` et `downloads.cursor.com`.

Aucun port entrant n'est nécessaire.

## Tailscale, seulement pour ouvrir l'interface soi-même

Inutile pour l'agent. Utile si le navigateur du Mac ou du téléphone doit ouvrir ntopng, le DSM ou la Freebox par leur IP locale.

Paquet Tailscale officiel sur le DSM. Même tailnet sur le Mac et le téléphone. Le NAS annonce seulement le sous-réseau de la maison. Approuver cette route dans la console Tailscale. Ne pas activer de exit node : le trafic Internet des vacances ne sort pas par la box.

Limiter l'accès à tes appareils, et aux ports utiles (ntopng, SSH, HTTPS du routeur et du DSM).

Essai en 4G, Tailscale actif : ouvrir la page ntopng par son IP locale. Sur DSM, le ping vers le LAN peut échouer alors que le TCP passe. La découverte broadcast ne traverse pas ce routage.

Limite DSM : le NAS peut annoncer des routes, il ne peut pas accepter les routes d'un autre subnet router. Ici les équipements sont sur son propre LAN, donc cette limite ne bloque pas l'agent.

## Repli

Si `agent` ne démarre pas dans le conteneur (architecture du NAS trop ancienne, ou Container Manager indisponible), le worker peut tourner sur le VPS. Le NAS ouvre alors un WireGuard sortant vers le VPS. Le pare-feu du VPS ne laisse passer que l'adresse de ntopng et un SSH, pas le reste du LAN.

Ce repli n'apporte pas de puissance : le modèle tourne chez Cursor dans les deux cas. On ne le met en place que si le conteneur du Synology a échoué.

## Ce qu'on ne fait pas

- Rediriger un port de la box vers ntopng, le DSM ou SSH.
- Placer le worker sur le VPS pour qu'il soit « plus puissant ».
- Publier ntopng sous un nom public.
- Commiter `.env` ou coller une clé dans le dépôt.
