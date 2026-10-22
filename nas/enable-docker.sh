#!/bin/bash
# À lancer une fois, avec sudo, depuis le compte Mika.
# Démarre Container Manager et donne au groupe administrators
# le droit d'utiliser Docker. À refaire après un redémarrage du NAS
# si /var/run/docker.sock redevient réservé à root.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Lance ce script avec sudo."
  exit 1
fi

/usr/syno/bin/synopkg start ContainerManager

for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  if [ -S /var/run/docker.sock ]; then
    break
  fi
  sleep 1
done

if [ ! -S /var/run/docker.sock ]; then
  echo "Container Manager n'a pas créé /var/run/docker.sock."
  exit 1
fi

chgrp administrators /var/run/docker.sock
chmod 660 /var/run/docker.sock
ls -l /var/run/docker.sock
echo "Docker est utilisable par le groupe administrators."
