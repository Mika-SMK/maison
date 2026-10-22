#!/bin/bash

###############################################################################
# SCRIPT DE DIAGNOSTIC - Omada & NtopNG
# Date: 22 octobre 2026
# Usage: bash diagnostic-network-tools.sh
###############################################################################

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symboles
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    DIAGNOSTIC DES OUTILS DE MONITORING RÉSEAU${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

###############################################################################
# 1. INFORMATIONS SYSTÈME
###############################################################################
echo -e "${YELLOW}[1/8] Informations Système${NC}"
echo "----------------------------------------"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'N/A')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo ""

###############################################################################
# 2. VÉRIFICATION DES SERVICES
###############################################################################
echo -e "${YELLOW}[2/8] Vérification des Services${NC}"
echo "----------------------------------------"

# NtopNG Service
if systemctl is-active --quiet ntopng 2>/dev/null; then
    echo -e "$CHECK NtopNG service: ${GREEN}ACTIF${NC}"
else
    echo -e "$CROSS NtopNG service: ${RED}INACTIF${NC}"
fi

# Omada Service
if systemctl is-active --quiet omadac 2>/dev/null || systemctl is-active --quiet tpeap 2>/dev/null; then
    echo -e "$CHECK Omada service: ${GREEN}ACTIF${NC}"
else
    echo -e "$CROSS Omada service: ${RED}INACTIF${NC}"
fi

# Docker Service
if systemctl is-active --quiet docker 2>/dev/null; then
    echo -e "$CHECK Docker service: ${GREEN}ACTIF${NC}"
else
    echo -e "$CROSS Docker service: ${RED}INACTIF${NC}"
fi
echo ""

###############################################################################
# 3. VÉRIFICATION DES PROCESSUS
###############################################################################
echo -e "${YELLOW}[3/8] Vérification des Processus${NC}"
echo "----------------------------------------"

# NtopNG Process
if pgrep -x ntopng > /dev/null; then
    echo -e "$CHECK NtopNG processus: ${GREEN}EN COURS${NC}"
    ps aux | grep ntopng | grep -v grep | head -1
else
    echo -e "$CROSS NtopNG processus: ${RED}NON TROUVÉ${NC}"
fi

# Omada Process
if pgrep -f omada > /dev/null || pgrep -f EAPController > /dev/null; then
    echo -e "$CHECK Omada processus: ${GREEN}EN COURS${NC}"
    ps aux | grep -E "(omada|EAPController)" | grep -v grep | head -1
else
    echo -e "$CROSS Omada processus: ${RED}NON TROUVÉ${NC}"
fi
echo ""

###############################################################################
# 4. VÉRIFICATION DES CONTENEURS DOCKER
###############################################################################
echo -e "${YELLOW}[4/8] Vérification des Conteneurs Docker${NC}"
echo "----------------------------------------"

if command -v docker &> /dev/null; then
    # NtopNG Container
    if docker ps 2>/dev/null | grep -q ntopng; then
        echo -e "$CHECK NtopNG container: ${GREEN}EN COURS${NC}"
        docker ps --filter "name=ntopng" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
    else
        echo -e "$CROSS NtopNG container: ${RED}NON TROUVÉ${NC}"
    fi
    
    # Omada Container
    if docker ps 2>/dev/null | grep -q omada; then
        echo -e "$CHECK Omada container: ${GREEN}EN COURS${NC}"
        docker ps --filter "name=omada" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
    else
        echo -e "$CROSS Omada container: ${RED}NON TROUVÉ${NC}"
    fi
else
    echo -e "$WARN Docker: ${YELLOW}COMMANDE NON DISPONIBLE${NC}"
fi
echo ""

###############################################################################
# 5. VÉRIFICATION DES PORTS
###############################################################################
echo -e "${YELLOW}[5/8] Vérification des Ports${NC}"
echo "----------------------------------------"

# Port 3000 (NtopNG)
if netstat -tulpn 2>/dev/null | grep -q ":3000 "; then
    echo -e "$CHECK Port 3000 (NtopNG): ${GREEN}EN ÉCOUTE${NC}"
    netstat -tulpn 2>/dev/null | grep ":3000 "
else
    echo -e "$CROSS Port 3000 (NtopNG): ${RED}FERMÉ${NC}"
fi

# Port 8043 (Omada HTTPS)
if netstat -tulpn 2>/dev/null | grep -q ":8043 "; then
    echo -e "$CHECK Port 8043 (Omada HTTPS): ${GREEN}EN ÉCOUTE${NC}"
    netstat -tulpn 2>/dev/null | grep ":8043 "
else
    echo -e "$CROSS Port 8043 (Omada HTTPS): ${RED}FERMÉ${NC}"
fi

# Port 8088 (Omada HTTP)
if netstat -tulpn 2>/dev/null | grep -q ":8088 "; then
    echo -e "$CHECK Port 8088 (Omada HTTP): ${GREEN}EN ÉCOUTE${NC}"
    netstat -tulpn 2>/dev/null | grep ":8088 "
else
    echo -e "$CROSS Port 8088 (Omada HTTP): ${RED}FERMÉ${NC}"
fi

echo ""
echo "Tous les ports en écoute:"
netstat -tulpn 2>/dev/null | grep LISTEN | awk '{print $4}' | sort -u
echo ""

###############################################################################
# 6. TEST DE CONNECTIVITÉ
###############################################################################
echo -e "${YELLOW}[6/8] Test de Connectivité${NC}"
echo "----------------------------------------"

# Test NtopNG HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "$CHECK NtopNG HTTP (localhost:3000): ${GREEN}ACCESSIBLE (code: $HTTP_CODE)${NC}"
else
    echo -e "$CROSS NtopNG HTTP (localhost:3000): ${RED}NON ACCESSIBLE (code: $HTTP_CODE)${NC}"
fi

# Test Omada HTTPS
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8043 2>/dev/null)
if [ "$HTTPS_CODE" = "200" ] || [ "$HTTPS_CODE" = "302" ]; then
    echo -e "$CHECK Omada HTTPS (localhost:8043): ${GREEN}ACCESSIBLE (code: $HTTPS_CODE)${NC}"
else
    echo -e "$CROSS Omada HTTPS (localhost:8043): ${RED}NON ACCESSIBLE (code: $HTTPS_CODE)${NC}"
fi

# Test Omada HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8088 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "$CHECK Omada HTTP (localhost:8088): ${GREEN}ACCESSIBLE (code: $HTTP_CODE)${NC}"
else
    echo -e "$CROSS Omada HTTP (localhost:8088): ${RED}NON ACCESSIBLE (code: $HTTP_CODE)${NC}"
fi
echo ""

###############################################################################
# 7. VÉRIFICATION DES BINAIRES
###############################################################################
echo -e "${YELLOW}[7/8] Vérification des Binaires${NC}"
echo "----------------------------------------"

# NtopNG Binary
if command -v ntopng &> /dev/null; then
    echo -e "$CHECK ntopng: ${GREEN}$(which ntopng)${NC}"
    ntopng --version 2>/dev/null || echo "  (version non disponible)"
else
    echo -e "$CROSS ntopng: ${RED}NON TROUVÉ${NC}"
fi

# Docker Binary
if command -v docker &> /dev/null; then
    echo -e "$CHECK docker: ${GREEN}$(which docker)${NC}"
    docker --version
else
    echo -e "$CROSS docker: ${RED}NON TROUVÉ${NC}"
fi

# Docker Compose Binary
if command -v docker-compose &> /dev/null; then
    echo -e "$CHECK docker-compose: ${GREEN}$(which docker-compose)${NC}"
    docker-compose --version
else
    echo -e "$CROSS docker-compose: ${RED}NON TROUVÉ${NC}"
fi
echo ""

###############################################################################
# 8. RECHERCHE DE FICHIERS DE CONFIGURATION
###############################################################################
echo -e "${YELLOW}[8/8] Fichiers de Configuration${NC}"
echo "----------------------------------------"

CONFIG_FOUND=0

# NtopNG Config
if [ -f /etc/ntopng/ntopng.conf ]; then
    echo -e "$CHECK /etc/ntopng/ntopng.conf"
    CONFIG_FOUND=1
fi

if [ -d /usr/share/ntopng ]; then
    echo -e "$CHECK /usr/share/ntopng/"
    CONFIG_FOUND=1
fi

# Omada Config
if [ -d /opt/tplink/EAPController ]; then
    echo -e "$CHECK /opt/tplink/EAPController/"
    CONFIG_FOUND=1
fi

if [ -f /workspace/docker-compose-monitoring.yml ]; then
    echo -e "$CHECK /workspace/docker-compose-monitoring.yml"
    CONFIG_FOUND=1
fi

if [ -f /workspace/.env ]; then
    echo -e "$CHECK /workspace/.env"
    if grep -q "NTOPNG\|OMADA" /workspace/.env 2>/dev/null; then
        echo "  → Contient des variables Omada/NtopNG"
    fi
    CONFIG_FOUND=1
fi

if [ $CONFIG_FOUND -eq 0 ]; then
    echo -e "$CROSS ${RED}Aucun fichier de configuration trouvé${NC}"
fi
echo ""

###############################################################################
# RÉSUMÉ & RECOMMANDATIONS
###############################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    RÉSUMÉ & RECOMMANDATIONS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Compter les problèmes
ISSUES=0

if ! pgrep -x ntopng > /dev/null && ! docker ps 2>/dev/null | grep -q ntopng; then
    echo -e "$CROSS ${RED}NtopNG n'est pas en cours d'exécution${NC}"
    ISSUES=$((ISSUES + 1))
fi

if ! pgrep -f omada > /dev/null && ! docker ps 2>/dev/null | grep -q omada; then
    echo -e "$CROSS ${RED}Omada n'est pas en cours d'exécution${NC}"
    ISSUES=$((ISSUES + 1))
fi

if ! command -v ntopng &> /dev/null; then
    echo -e "$CROSS ${RED}NtopNG n'est pas installé${NC}"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les services semblent fonctionnels !${NC}"
else
    echo ""
    echo -e "${YELLOW}ACTIONS RECOMMANDÉES:${NC}"
    echo ""
    echo "1. Consulter le document: /workspace/ISSUE_OMADA_NTOPNG_ACCESS.md"
    echo "2. Choisir une méthode d'installation (Docker ou native)"
    echo "3. Exécuter le script d'installation approprié"
    echo "4. Relancer ce diagnostic pour valider"
    echo ""
    echo "Installation rapide via Docker:"
    echo "  cd /workspace"
    echo "  docker-compose -f docker-compose-monitoring.yml up -d"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
