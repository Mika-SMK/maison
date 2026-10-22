# 🔧 Guide Rapide - Installation Omada & NtopNG

## 🚀 Installation Rapide

### Prérequis
- Docker installé et fonctionnel
- Docker Compose installé
- Accès root ou sudo

### Méthode 1 : Via Docker Compose (Recommandé)

```bash
# 1. Aller dans le workspace
cd /workspace

# 2. Lancer les services
docker-compose -f docker-compose-monitoring.yml up -d

# 3. Vérifier le statut
docker-compose -f docker-compose-monitoring.yml ps

# 4. Accéder aux interfaces
# NtopNG: http://localhost:3000 (admin/admin)
# Omada: https://localhost:8043
```

### Méthode 2 : Script de diagnostic

```bash
# Lancer le diagnostic complet
bash /workspace/scripts/diagnostic-network-tools.sh
```

## 📚 Documentation Complète

Consultez le document détaillé pour toutes les options d'installation :
```
/workspace/ISSUE_OMADA_NTOPNG_ACCESS.md
```

## 🔍 Vérification Rapide

```bash
# Tester NtopNG
curl http://localhost:3000

# Tester Omada
curl -k https://localhost:8043

# Voir les logs
docker logs ntopng
docker logs omada-controller
```

## 🛑 Arrêt des Services

```bash
docker-compose -f docker-compose-monitoring.yml down
```

## 📝 Accès par Défaut

### NtopNG
- URL: http://localhost:3000
- Utilisateur: `admin`
- Mot de passe: `admin`

### Omada Controller
- URL: https://localhost:8043
- Premier accès: Configuration guidée
- Ports secondaires: 8088 (HTTP), 8843 (Portal)

## ⚠️ Troubleshooting

### Conflit de ports
```bash
# Vérifier les ports utilisés
netstat -tulpn | grep -E "(3000|8043|8088)"

# Modifier les ports dans docker-compose-monitoring.yml si nécessaire
```

### Permissions réseau
```bash
# NtopNG nécessite des privilèges réseau
# Vérifié automatiquement dans docker-compose (cap_add)
```

## 📧 Support

Pour toute question, consulter :
1. `/workspace/ISSUE_OMADA_NTOPNG_ACCESS.md` - Documentation complète
2. Logs des conteneurs: `docker logs <nom_conteneur>`
3. Script de diagnostic: `bash /workspace/scripts/diagnostic-network-tools.sh`
