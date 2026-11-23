#!/bin/bash
# Incremente le numero de version de deploiement partage par les rapports.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/DEPLOY_VERSION"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "Erreur: fichier DEPLOY_VERSION introuvable." >&2
  exit 1
fi

current="$(tr -d '\r\n' <"${VERSION_FILE}")"
if [[ ! "${current}" =~ ^[0-9]+$ ]]; then
  echo "Erreur: DEPLOY_VERSION doit etre un entier, valeur actuelle='${current}'." >&2
  exit 1
fi

next=$((current + 1))
printf '%s\n' "${next}" >"${VERSION_FILE}"
echo "deploy_version=${next}"
