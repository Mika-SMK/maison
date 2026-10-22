# 🔴 PROBLÈME D'ACCÈS : Omada Controller & NtopNG

**Date du rapport** : 22 octobre 2026 - 15:40 UTC+2  
**Agent** : Cloud Agent Cursor (bc-01a163d1-c084-715b-8838-f92755ed864b)  
**Environnement** : Cloud Agent VM - Linux Ubuntu  
**Gravité** : ⚠️ HAUTE - Outils de monitoring réseau indisponibles

---

## 📋 RÉSUMÉ EXÉCUTIF

L'agent est censé avoir accès à **TP-Link Omada Controller** et **NtopNG** pour effectuer des analyses de sécurité réseau, mais aucun de ces outils n'est actuellement disponible dans l'environnement.

### Symptômes
- ✗ Omada Controller non trouvé
- ✗ NtopNG non installé
- ✗ Aucun service de monitoring réseau disponible
- ✗ Impossible d'effectuer une analyse réseau approfondie

---

## 🔍 ANALYSE DÉTAILLÉE

### 1. Vérifications Effectuées

#### A. Recherche de Services Système
```bash
# Vérification des services
systemctl status ntopng         # ❌ Service non trouvé
systemctl status omadac         # ❌ Service non trouvé
systemctl status tpeap          # ❌ Service non trouvé

# Recherche de processus
ps aux | grep ntopng            # ❌ Aucun processus
ps aux | grep omada             # ❌ Aucun processus
```

**Résultat** : Aucun service en cours d'exécution

#### B. Recherche de Paquets Installés
```bash
# Paquets Debian/Ubuntu
dpkg -l | grep ntopng           # ❌ Non installé
dpkg -l | grep omada            # ❌ Non installé

# Binaires
which ntopng                    # ❌ Commande introuvable
find /usr/local/bin -name "*ntopng*"  # ❌ Aucun résultat
find /opt -name "*omada*"       # ❌ Aucun résultat
```

**Résultat** : Aucun paquet installé

#### C. Recherche de Conteneurs Docker
```bash
# Vérification des conteneurs
docker ps -a | grep ntopng      # ❌ Aucun conteneur
docker ps -a | grep omada       # ❌ Aucun conteneur

# Images Docker disponibles
docker images | grep ntopng     # ❌ Aucune image
docker images | grep omada      # ❌ Aucune image
```

**Résultat** : Aucun conteneur Docker

#### D. Vérification des Ports Standards
```bash
# Ports testés
curl http://localhost:3000      # ❌ NtopNG (port par défaut) - Pas de réponse
curl http://localhost:8043      # ❌ Omada (port par défaut) - Pas de réponse
curl http://localhost:8088      # ❌ Omada HTTP - Pas de réponse
curl https://localhost:8843     # ❌ Omada HTTPS - Pas de réponse
```

**Ports actuellement en écoute** :
- 2375 : Docker API (non sécurisé)
- 26053/26054 : Exec Daemon Cursor
- 26058 : noVNC WebSocket
- 5901 : VNC Server (localhost uniquement)
- 26500/50052 : Services internes

**Résultat** : Aucun port Omada/NtopNG actif

#### E. Recherche dans le Workspace
```bash
# Fichiers de configuration
find /workspace -name "*ntop*"  # ❌ Aucun résultat
find /workspace -name "*omada*" # ❌ Aucun résultat

# Variables d'environnement
env | grep -i ntop              # ❌ Aucune variable
env | grep -i omada             # ❌ Aucune variable
```

**Résultat** : Aucune configuration dans le workspace

---

## 🎯 ÉTAT ATTENDU vs ÉTAT ACTUEL

### État Attendu (selon l'utilisateur)
```
✅ Omada Controller accessible et fonctionnel
✅ NtopNG installé et capable d'analyser le trafic réseau
✅ Agent capable de :
   - Analyser les intrusions réseau via NtopNG
   - Vérifier la configuration réseau via Omada
   - Générer des rapports de sécurité complets
```

### État Actuel (constaté)
```
❌ Aucun outil de monitoring réseau disponible
❌ Impossibilité d'analyser le trafic en temps réel
❌ Analyse limitée aux commandes système de base (netstat, ps, etc.)
❌ Pas d'accès aux statistiques réseau détaillées
```

---

## 🛠️ SOLUTIONS PROPOSÉES

### Solution 1 : Installation Locale (Recommandé pour VM permanente)

#### A. Installation de NtopNG
```bash
# Ajouter le dépôt NtopNG
wget https://packages.ntop.org/apt/ntop.key -O - | sudo apt-key add -
echo "deb https://packages.ntop.org/apt/stable/ubuntu/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/ntop.list

# Installer NtopNG
sudo apt update
sudo apt install -y ntopng ntopng-data pfring-dkms

# Configuration de base
sudo systemctl enable ntopng
sudo systemctl start ntopng

# Vérification
curl http://localhost:3000
```

**Ports NtopNG** :
- Interface Web : `http://localhost:3000`
- Identifiants par défaut : `admin` / `admin`

#### B. Installation d'Omada Controller
```bash
# Option 1 : Via Docker (recommandé)
docker run -d \
  --name omada-controller \
  --restart unless-stopped \
  -p 8088:8088 \
  -p 8043:8043 \
  -p 8843:8843 \
  -p 27001:27001/udp \
  -p 29810-29814:29810-29814 \
  -v omada-data:/opt/tplink/EAPController/data \
  -v omada-logs:/opt/tplink/EAPController/logs \
  -e TZ=Europe/Paris \
  mbentley/omada-controller:latest

# Vérification
docker ps | grep omada
curl -k https://localhost:8043
```

**Ports Omada** :
- Interface Web : `https://localhost:8043`
- HTTP : `http://localhost:8088`
- Portal HTTPS : `https://localhost:8843`

```bash
# Option 2 : Installation native (Ubuntu/Debian)
wget https://static.tp-link.com/upload/software/2023/202312/20231211/Omada_SDN_Controller_v5.13.30.8_linux_x64.deb
sudo dpkg -i Omada_SDN_Controller_v5.13.30.8_linux_x64.deb
sudo apt-get install -f  # Résoudre les dépendances
sudo systemctl enable omadac
sudo systemctl start omadac
```

---

### Solution 2 : Configuration via Docker Compose (Recommandé pour environnement de développement)

Créer un fichier `/workspace/docker-compose-monitoring.yml` :

```yaml
version: '3.8'

services:
  ntopng:
    image: vimagick/ntopng
    container_name: ntopng
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
    environment:
      - INTERFACE=eth0
    ports:
      - "3000:3000"
    volumes:
      - ntopng-data:/var/lib/ntopng

  omada-controller:
    image: mbentley/omada-controller:latest
    container_name: omada-controller
    restart: unless-stopped
    environment:
      - TZ=Europe/Paris
      - MANAGE_HTTP_PORT=8088
      - MANAGE_HTTPS_PORT=8043
      - PORTAL_HTTP_PORT=8088
      - PORTAL_HTTPS_PORT=8843
    ports:
      - "8088:8088"
      - "8043:8043"
      - "8843:8843"
      - "27001:27001/udp"
      - "29810:29810"
      - "29811:29811"
      - "29812:29812"
      - "29813:29813"
      - "29814:29814"
    volumes:
      - omada-data:/opt/tplink/EAPController/data
      - omada-logs:/opt/tplink/EAPController/logs

volumes:
  ntopng-data:
    driver: local
  omada-data:
    driver: local
  omada-logs:
    driver: local
```

**Démarrage** :
```bash
cd /workspace
docker-compose -f docker-compose-monitoring.yml up -d
```

---

### Solution 3 : Accès Distant (Si services déjà déployés ailleurs)

Si Omada et NtopNG sont déjà installés sur un serveur distant :

#### Configuration de l'accès
```bash
# Ajouter les variables d'environnement dans .env
cat >> /workspace/.env << EOF
NTOPNG_URL=http://<IP_SERVEUR>:3000
NTOPNG_USERNAME=admin
NTOPNG_PASSWORD=<mot_de_passe>

OMADA_URL=https://<IP_SERVEUR>:8043
OMADA_USERNAME=admin
OMADA_PASSWORD=<mot_de_passe>
EOF

# Tester l'accès
curl -u admin:password http://<IP_SERVEUR>:3000
curl -k https://<IP_SERVEUR>:8043
```

#### Script de connexion
Créer `/workspace/scripts/check-network-tools.sh` :

```bash
#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Vérification des outils réseau ==="

# Test NtopNG
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}✓ NtopNG accessible${NC}"
else
    echo -e "${RED}✗ NtopNG non accessible${NC}"
fi

# Test Omada
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8043 | grep -q "200"; then
    echo -e "${GREEN}✓ Omada accessible${NC}"
else
    echo -e "${RED}✗ Omada non accessible${NC}"
fi
```

---

## 🔧 CONFIGURATION DE L'ENVIRONNEMENT CLOUD AGENT

### Fichier environment.json à modifier

Si cet environnement doit toujours avoir accès à ces outils, ajouter dans `.cursor/environment.json` :

```json
{
  "version": "1.0",
  "name": "Network Security Environment",
  "repos": [
    {
      "url": "https://github.com/<votre-repo>.git",
      "branch": "master"
    }
  ],
  "install": {
    "script": "bash scripts/setup-monitoring.sh"
  },
  "start": {
    "script": "docker-compose -f docker-compose-monitoring.yml up -d"
  },
  "env": {
    "TZ": "Europe/Paris",
    "NTOPNG_ENABLED": "true",
    "OMADA_ENABLED": "true"
  }
}
```

### Script d'installation à créer

Créer `/workspace/scripts/setup-monitoring.sh` :

```bash
#!/bin/bash
set -e

echo "=== Installation des outils de monitoring réseau ==="

# Installation de NtopNG
echo "Installation de NtopNG..."
wget -qO - https://packages.ntop.org/apt/ntop.key | sudo apt-key add -
echo "deb https://packages.ntop.org/apt/stable/ubuntu/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/ntop.list
sudo apt update
sudo apt install -y ntopng ntopng-data

# Installation de Docker (si nécessaire)
if ! command -v docker &> /dev/null; then
    echo "Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Installation de Docker Compose (si nécessaire)
if ! command -v docker-compose &> /dev/null; then
    echo "Installation de Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Démarrage de NtopNG
sudo systemctl enable ntopng
sudo systemctl start ntopng

# Démarrage d'Omada via Docker
echo "Démarrage d'Omada Controller..."
docker run -d \
  --name omada-controller \
  --restart unless-stopped \
  -p 8088:8088 \
  -p 8043:8043 \
  -p 8843:8843 \
  -e TZ=Europe/Paris \
  mbentley/omada-controller:latest

echo "✅ Installation terminée !"
echo "NtopNG: http://localhost:3000"
echo "Omada: https://localhost:8043"
```

Rendre le script exécutable :
```bash
chmod +x /workspace/scripts/setup-monitoring.sh
```

---

## 📊 TESTS DE VALIDATION

### Checklist après installation

```bash
# 1. Vérifier NtopNG
curl -I http://localhost:3000
# Attendu : HTTP/1.1 200 OK

# 2. Vérifier Omada
curl -Ik https://localhost:8043
# Attendu : HTTP/1.1 200 OK ou redirection

# 3. Vérifier les services
sudo systemctl status ntopng
docker ps | grep omada

# 4. Vérifier les logs
sudo journalctl -u ntopng -n 50
docker logs omada-controller --tail 50

# 5. Test d'accès depuis l'agent
python3 << EOF
import requests
import urllib3
urllib3.disable_warnings()

# Test NtopNG
try:
    r = requests.get('http://localhost:3000', timeout=5)
    print(f"✓ NtopNG: {r.status_code}")
except Exception as e:
    print(f"✗ NtopNG: {e}")

# Test Omada
try:
    r = requests.get('https://localhost:8043', verify=False, timeout=5)
    print(f"✓ Omada: {r.status_code}")
except Exception as e:
    print(f"✗ Omada: {e}")
EOF
```

---

## 🚨 PROBLÈMES POTENTIELS & SOLUTIONS

### Problème 1 : Port 3000 déjà utilisé
```bash
# Identifier le processus
sudo lsof -i :3000
# Changer le port de NtopNG
sudo nano /etc/ntopng/ntopng.conf
# Ajouter : --http-port=3001
sudo systemctl restart ntopng
```

### Problème 2 : Conflit de ports Omada
```bash
# Vérifier les ports utilisés
sudo netstat -tulpn | grep -E "(8043|8088|8843)"
# Modifier les ports dans docker run avec -p 9043:8043 etc.
```

### Problème 3 : Permissions insuffisantes
```bash
# NtopNG nécessite des privilèges réseau
sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/ntopng

# Docker nécessite l'accès groupe
sudo usermod -aG docker $USER
newgrp docker
```

### Problème 4 : Interface réseau non détectée
```bash
# Lister les interfaces
ip link show

# Configurer NtopNG pour l'interface correcte
sudo nano /etc/ntopng/ntopng.conf
# Modifier : -i=eth0 (ou votre interface)
```

---

## 📝 INFORMATIONS COMPLÉMENTAIRES

### Environnement Actuel
```
OS: Linux Ubuntu (kernel 6.12.94+)
Shell: bash
Workspace: /workspace
User: ubuntu (UID 1000)
Architecture: x86_64
```

### Services Actuellement Disponibles
```
✓ Docker API (port 2375) - ⚠️ NON SÉCURISÉ
✓ Exec Daemon Cursor (ports 26053/26054)
✓ VNC Server (port 5901, localhost uniquement)
✓ noVNC WebSocket (port 26058)
```

### Ressources Système
```bash
# Vérifier les ressources disponibles
free -h
df -h
docker stats --no-stream
```

---

## 🎯 ACTIONS REQUISES POUR L'AGENT DE DÉVELOPPEMENT

### Priorité HAUTE 🔴
1. **Déterminer l'architecture cible** :
   - Installation locale ou accès distant ?
   - Conteneurs Docker ou installation native ?
   - Environnement permanent ou temporaire ?

2. **Implémenter la solution choisie** :
   - Exécuter le script d'installation approprié
   - Configurer les accès et permissions
   - Valider les tests de connectivité

3. **Documenter la configuration** :
   - Mettre à jour `.cursor/environment.json`
   - Créer/mettre à jour les scripts de setup
   - Ajouter les variables d'environnement nécessaires

### Priorité MOYENNE 🟡
4. **Sécuriser l'environnement** :
   - Configurer l'authentification pour NtopNG et Omada
   - Limiter l'accès réseau (firewall/iptables)
   - Changer les mots de passe par défaut

5. **Automatiser le monitoring** :
   - Créer des scripts d'analyse automatique
   - Configurer des alertes
   - Intégrer avec les workflows de l'agent

### Priorité BASSE 🟢
6. **Optimisations** :
   - Configurer la rétention des données
   - Optimiser les performances
   - Créer des dashboards personnalisés

---

## 📞 CONTACT & SUPPORT

**Logs de la session d'analyse** : Disponibles dans le transcript de l'agent  
**ID de l'agent** : `bc-01a163d1-c084-715b-8838-f92755ed864b`  
**Date du rapport** : 22 octobre 2026 - 15:40 UTC+2

---

## 📚 RÉFÉRENCES

- Documentation NtopNG : https://www.ntop.org/guides/ntopng/
- Documentation Omada : https://www.tp-link.com/en/support/download/omada-software-controller/
- Docker Image Omada : https://hub.docker.com/r/mbentley/omada-controller
- Installation NtopNG Ubuntu : https://packages.ntop.org/

---

**FIN DU RAPPORT**
