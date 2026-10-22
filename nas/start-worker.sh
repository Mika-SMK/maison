#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export PATH="/root/.local/bin:${PATH}"

if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl git bash
  rm -rf /var/lib/apt/lists/*
fi

if ! command -v agent >/dev/null 2>&1; then
  curl https://cursor.com/install -fsS | bash
  export PATH="/root/.local/bin:${PATH}"
fi

if [ -z "${CURSOR_API_KEY:-}" ]; then
  echo "CURSOR_API_KEY est vide. Renseigne-le dans .env sur le NAS, puis redémarre le conteneur."
  exit 1
fi

if [ ! -d /workspace/.git ]; then
  echo "Aucun dépôt git dans /workspace."
  exit 1
fi

git config --global --add safe.directory /workspace

if ! git -C /workspace remote get-url origin >/dev/null 2>&1; then
  echo "Le dépôt /workspace n'a pas de remote origin. La machine n'apparaîtra pas dans le sélecteur Cursor."
  exit 1
fi

exec agent worker start \
  --name maison \
  --worker-dir /workspace \
  --api-key "${CURSOR_API_KEY}"
