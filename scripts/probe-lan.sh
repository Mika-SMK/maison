#!/bin/bash
# Preuve d'accès LAN depuis le worker. N'installe rien.
set -euo pipefail
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 "$url" || echo "000")
  printf '%-12s %s  %s\n' "$name" "$code" "$url"
}
echo "host=$(hostname) kernel=$(uname -r)"
probe omada  "https://127.0.0.1:8043/"
probe ntopng "http://127.0.0.1:3000/"
probe freebox "http://192.168.1.254/api_version"
probe ha     "http://192.168.1.60:8123/api/"
echo "200/302 = joignable. 000 = tu n'es pas sur la machine maison."
