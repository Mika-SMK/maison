#!/bin/bash
# Rapport LAN avec retention glissante (7 jours), table paginee et logique mobile/fixe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT_DIR_DEFAULT="${ROOT_DIR}/.maison-reports"

RETENTION_DAYS=7
PAGE=1
PAGE_SIZE=12
DEVICES_FILE=""
AUTO_HEAL_MOBILE=0
REPORT_DIR="${REPORT_DIR_DEFAULT}"
MOBILE_DISCONNECT_CMD="${MOBILE_DISCONNECT_CMD:-}"

CURRENT_OK=0
CURRENT_INFO=0
CURRENT_WARN=0
CURRENT_ERROR=0
CURRENT_CRITICAL=0

usage() {
  cat <<'USAGE'
Usage:
  scripts/probe-lan.sh [options]

Options:
  --devices-file <path>         CSV des devices:
                                name,mac,rssi,ap,expected_ap,mobility
                                mobility optionnel: mobile|fixed
  --page <n>                    Numero de page (defaut: 1)
  --page-size <n>               Lignes par page (defaut: 12)
  --report-dir <path>           Dossier de stockage du rapport
  --auto-heal-mobile            Tente de deconnecter les mobiles en signal faible
  --mobile-disconnect-cmd <cmd> Commande a executer pour deconnecter:
                                <cmd> <mac> <name>
  -h, --help                    Afficher cette aide
USAGE
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

to_lower() {
  local value="$1"
  printf '%s' "${value,,}"
}

report_file() {
  printf '%s/network-events.tsv' "${REPORT_DIR}"
}

ensure_report_file() {
  mkdir -p "${REPORT_DIR}"
  local file
  file="$(report_file)"
  if [[ ! -f "${file}" ]]; then
    printf 'epoch\tiso_utc\tscope\tentity\tstatus\tseverity\tdetails\taction\n' >"${file}"
  fi
}

increment_severity() {
  local severity="$1"
  case "${severity}" in
    OK) ((CURRENT_OK += 1)) ;;
    INFO) ((CURRENT_INFO += 1)) ;;
    WARN) ((CURRENT_WARN += 1)) ;;
    ERROR) ((CURRENT_ERROR += 1)) ;;
    CRITICAL) ((CURRENT_CRITICAL += 1)) ;;
  esac
}

sanitize_field() {
  local value="$1"
  value="${value//$'\t'/ }"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

append_event() {
  local epoch="$1"
  local iso_utc="$2"
  local scope="$3"
  local entity="$4"
  local status="$5"
  local severity="$6"
  local details="$7"
  local action="$8"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${epoch}" \
    "$(sanitize_field "${iso_utc}")" \
    "$(sanitize_field "${scope}")" \
    "$(sanitize_field "${entity}")" \
    "$(sanitize_field "${status}")" \
    "$(sanitize_field "${severity}")" \
    "$(sanitize_field "${details}")" \
    "$(sanitize_field "${action}")" \
    >>"$(report_file)"
  increment_severity "${severity}"
}

prune_history() {
  local min_epoch="$1"
  local file tmp_file
  file="$(report_file)"
  tmp_file="${file}.tmp"
  awk -F'\t' -v min_epoch="${min_epoch}" 'NR==1 || ($1+0) >= min_epoch' "${file}" >"${tmp_file}"
  mv "${tmp_file}" "${file}"
}

truncate_field() {
  local value="$1"
  local max_len="$2"
  if (( ${#value} <= max_len )); then
    printf '%s' "$value"
  else
    printf '%s...' "${value:0:max_len-3}"
  fi
}

classify_http_probe() {
  local code="$1"
  local status severity details action
  case "${code}" in
    200|204|302)
      status="reachable"
      severity="OK"
      details="Service joignable (HTTP ${code})"
      action="-"
      ;;
    401|403)
      status="auth-required"
      severity="WARN"
      details="Service joignable mais authentification requise (HTTP ${code})"
      action="Verifier les credentials dans .env"
      ;;
    404)
      status="endpoint-not-found"
      severity="WARN"
      details="Service joignable mais endpoint absent (HTTP 404)"
      action="Verifier l'URL cible"
      ;;
    000)
      status="unreachable"
      severity="ERROR"
      details="Aucune reponse (timeout/reseau)"
      action="Verifier execution sur machine maison/LAN"
      ;;
    *)
      status="http-error"
      severity="ERROR"
      details="Reponse HTTP inattendue (${code})"
      action="Consulter les logs du service"
      ;;
  esac
  printf '%s\t%s\t%s\t%s' "${status}" "${severity}" "${details}" "${action}"
}

probe_service() {
  local epoch="$1"
  local iso_utc="$2"
  local service="$3"
  local url="$4"
  local code result status severity details action
  code="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 "${url}" || true)"
  if [[ -z "${code}" ]]; then
    code="000"
  fi
  result="$(classify_http_probe "${code}")"
  IFS=$'\t' read -r status severity details action <<<"${result}"
  append_event "${epoch}" "${iso_utc}" "service" "${service}" "${status}" "${severity}" "${details}" "${action}"
}

infer_mobility() {
  local device_name_lc="$1"
  case "${device_name_lc}" in
    *macbook*|*iphone*|*ipad*|*android*|*pixel*|*phone*|*mobile*|*tablet*|*laptop*|*watch*)
      printf 'mobile'
      ;;
    *refoss*|*frigo*|*prise*|*plug*|*camera*|*cam*|*tv*|*shelly*|*dw2*|*switch*|*imprim*|*printer*)
      printf 'fixed'
      ;;
    *)
      # Par defaut, on traite comme fixe pour eviter de masquer un vrai probleme.
      printf 'fixed'
      ;;
  esac
}

attempt_mobile_reconnect() {
  local epoch="$1"
  local iso_utc="$2"
  local device_name="$3"
  local mac="$4"

  if (( AUTO_HEAL_MOBILE == 0 )); then
    append_event "${epoch}" "${iso_utc}" "auto-heal" "${device_name}" \
      "reconnect-skipped" "INFO" \
      "Signal faible detecte sur mobile; reconnexion non activee" \
      "Relancer avec --auto-heal-mobile"
    return
  fi

  if [[ -z "${MOBILE_DISCONNECT_CMD}" ]]; then
    append_event "${epoch}" "${iso_utc}" "auto-heal" "${device_name}" \
      "reconnect-skipped" "WARN" \
      "Signal faible detecte mais aucune commande de deconnexion configuree" \
      "Ajouter --mobile-disconnect-cmd"
    return
  fi

  if ! command -v "${MOBILE_DISCONNECT_CMD}" >/dev/null 2>&1; then
    append_event "${epoch}" "${iso_utc}" "auto-heal" "${device_name}" \
      "reconnect-failed" "ERROR" \
      "Commande ${MOBILE_DISCONNECT_CMD} introuvable" \
      "Installer/configurer la commande de deconnexion"
    return
  fi

  if "${MOBILE_DISCONNECT_CMD}" "${mac}" "${device_name}" >/dev/null 2>&1; then
    append_event "${epoch}" "${iso_utc}" "auto-heal" "${device_name}" \
      "reconnect-triggered" "INFO" \
      "Deconnexion demandee pour forcer une reassociation Wi-Fi" \
      "Verifier la qualite apres reconnexion"
  else
    append_event "${epoch}" "${iso_utc}" "auto-heal" "${device_name}" \
      "reconnect-failed" "ERROR" \
      "La commande de deconnexion a echoue" \
      "Verifier droits/API/commande"
  fi
}

analyze_devices_file() {
  local epoch="$1"
  local iso_utc="$2"
  local file="$3"
  local line_no=0
  local name mac rssi ap expected_ap mobility inferred_mobility mobility_lc
  local quality severity status details action ap_lc expected_ap_lc

  if [[ ! -f "${file}" ]]; then
    append_event "${epoch}" "${iso_utc}" "parser" "devices-file" \
      "file-missing" "ERROR" \
      "Fichier devices absent: ${file}" \
      "Verifier le chemin passe a --devices-file"
    return
  fi

  while IFS=',' read -r name mac rssi ap expected_ap mobility extra; do
    ((line_no += 1))
    if (( line_no == 1 )) && [[ "$(to_lower "$(trim "${name}")")" == "name" ]]; then
      continue
    fi
    if [[ -z "$(trim "${name}")" ]]; then
      continue
    fi
    if [[ "$(trim "${name}")" == \#* ]]; then
      continue
    fi

    name="$(trim "${name}")"
    mac="$(trim "${mac}")"
    rssi="$(trim "${rssi}")"
    ap="$(trim "${ap}")"
    expected_ap="$(trim "${expected_ap}")"
    mobility="$(trim "${mobility}")"

    inferred_mobility="$(infer_mobility "$(to_lower "${name}")")"
    if [[ -n "${mobility}" ]]; then
      mobility_lc="$(to_lower "${mobility}")"
      if [[ "${mobility_lc}" == "mobile" || "${mobility_lc}" == "fixed" ]]; then
        inferred_mobility="${mobility_lc}"
      fi
    fi

    # Regle association AP: stricte sur fixed, souple sur mobile.
    if [[ -n "${expected_ap}" && -n "${ap}" ]]; then
      ap_lc="$(to_lower "${ap}")"
      expected_ap_lc="$(to_lower "${expected_ap}")"
      if [[ "${ap_lc}" != "${expected_ap_lc}" ]]; then
        if [[ "${inferred_mobility}" == "mobile" ]]; then
          append_event "${epoch}" "${iso_utc}" "association" "${name}" \
            "mobility-allowed" "INFO" \
            "Associe a ${ap} au lieu de ${expected_ap}, mobile donc acceptable" \
            "Aucune action"
        else
          append_event "${epoch}" "${iso_utc}" "association" "${name}" \
            "unexpected-ap" "WARN" \
            "Associe a ${ap} au lieu de ${expected_ap} (device fixe)" \
            "Verifier couverture/interferences/cablage"
        fi
      fi
    fi

    # Qualite RSSI et action auto-heal pour mobile en souffrance.
    if [[ ! "${rssi}" =~ ^-?[0-9]+$ ]]; then
      append_event "${epoch}" "${iso_utc}" "quality" "${name}" \
        "missing-rssi" "WARN" \
        "RSSI absent ou invalide (${rssi:-vide})" \
        "Verifier la collecte Omada"
      continue
    fi

    if (( rssi >= -65 )); then
      quality="good"
      severity="OK"
      status="quality-good"
      details="RSSI ${rssi} dBm (bon)"
      action="-"
    elif (( rssi >= -75 )); then
      quality="fair"
      status="quality-fair"
      if [[ "${inferred_mobility}" == "mobile" ]]; then
        severity="INFO"
        details="RSSI ${rssi} dBm (moyen, mobile)"
        action="Observer la tendance"
      else
        severity="WARN"
        details="RSSI ${rssi} dBm (moyen, fixe)"
        action="Verifier position/AP"
      fi
    else
      quality="poor"
      status="quality-poor"
      if [[ "${inferred_mobility}" == "mobile" ]]; then
        severity="WARN"
        details="RSSI ${rssi} dBm (faible, mobile)"
        action="Tentative de reconnexion possible"
      else
        severity="CRITICAL"
        details="RSSI ${rssi} dBm (faible, fixe)"
        action="Corriger couverture/AP prioritairement"
      fi
    fi

    append_event "${epoch}" "${iso_utc}" "quality" "${name}" "${status}" "${severity}" "${details}" "${action}"

    if [[ "${quality}" == "poor" && "${inferred_mobility}" == "mobile" ]]; then
      attempt_mobile_reconnect "${epoch}" "${iso_utc}" "${name}" "${mac}"
    fi
  done <"${file}"
}

render_table() {
  local now_epoch="$1"
  local min_epoch="$2"
  local file
  file="$(report_file)"

  mapfile -t rows < <(awk -F'\t' -v min_epoch="${min_epoch}" 'NR>1 && ($1+0) >= min_epoch { print }' "${file}" | sort -t$'\t' -k1,1nr)
  local total="${#rows[@]}"

  if (( total == 0 )); then
    echo
    echo "Aucun evenement sur la fenetre glissante de 7 jours."
    return
  fi

  local total_pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
  if (( PAGE > total_pages )); then
    PAGE="${total_pages}"
  fi
  if (( PAGE < 1 )); then
    PAGE=1
  fi

  local start_idx=$(( (PAGE - 1) * PAGE_SIZE ))
  local end_idx=$(( start_idx + PAGE_SIZE ))
  if (( end_idx > total )); then
    end_idx="${total}"
  fi

  echo
  printf 'Rapport reseau (7 jours glissants) - page %d/%d - %d evenement(s)\n' "${PAGE}" "${total_pages}" "${total}"
  printf 'Fenetre UTC: %s -> %s\n' \
    "$(date -u -d "@${min_epoch}" '+%Y-%m-%d %H:%M:%S')" \
    "$(date -u -d "@${now_epoch}" '+%Y-%m-%d %H:%M:%S')"
  echo
  printf '%-19s | %-11s | %-18s | %-16s | %-8s | %-40s | %-34s\n' "Timestamp (UTC)" "Scope" "Entite" "Statut" "Niveau" "Details" "Action"
  printf '%s\n' "--------------------+-------------+--------------------+------------------+----------+------------------------------------------+------------------------------------"

  local i
  for (( i = start_idx; i < end_idx; i++ )); do
    local epoch iso_utc scope entity status severity details action
    IFS=$'\t' read -r epoch iso_utc scope entity status severity details action <<<"${rows[$i]}"
    printf '%-19s | %-11s | %-18s | %-16s | %-8s | %-40s | %-34s\n' \
      "$(truncate_field "${iso_utc}" 19)" \
      "$(truncate_field "${scope}" 11)" \
      "$(truncate_field "${entity}" 18)" \
      "$(truncate_field "${status}" 16)" \
      "$(truncate_field "${severity}" 8)" \
      "$(truncate_field "${details}" 40)" \
      "$(truncate_field "${action}" 34)"
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --devices-file)
        DEVICES_FILE="${2:-}"
        shift 2
        ;;
      --page)
        PAGE="${2:-}"
        shift 2
        ;;
      --page-size)
        PAGE_SIZE="${2:-}"
        shift 2
        ;;
      --report-dir)
        REPORT_DIR="${2:-}"
        shift 2
        ;;
      --auto-heal-mobile)
        AUTO_HEAL_MOBILE=1
        shift
        ;;
      --mobile-disconnect-cmd)
        MOBILE_DISCONNECT_CMD="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Option inconnue: $1" >&2
        usage >&2
        exit 64
        ;;
    esac
  done

  if ! [[ "${PAGE}" =~ ^[0-9]+$ ]] || (( PAGE < 1 )); then
    echo "Erreur: --page doit etre un entier >= 1." >&2
    exit 64
  fi
  if ! [[ "${PAGE_SIZE}" =~ ^[0-9]+$ ]] || (( PAGE_SIZE < 1 )); then
    echo "Erreur: --page-size doit etre un entier >= 1." >&2
    exit 64
  fi
}

main() {
  parse_args "$@"

  local now_epoch now_iso min_epoch
  now_epoch="$(date -u +%s)"
  now_iso="$(date -u '+%Y-%m-%d %H:%M:%S')"
  min_epoch="$(( now_epoch - RETENTION_DAYS * 86400 ))"

  ensure_report_file
  prune_history "${min_epoch}"

  echo "host=$(hostname) kernel=$(uname -r)"
  echo "collecte_utc=${now_iso}"
  echo "retention=${RETENTION_DAYS}j report_dir=${REPORT_DIR}"

  probe_service "${now_epoch}" "${now_iso}" "omada" "https://127.0.0.1:8043/"
  probe_service "${now_epoch}" "${now_iso}" "ntopng" "http://127.0.0.1:3000/"
  probe_service "${now_epoch}" "${now_iso}" "freebox" "http://192.168.1.254/api_version"
  probe_service "${now_epoch}" "${now_iso}" "home-assistant" "http://192.168.1.60:8123/api/"

  if [[ -n "${DEVICES_FILE}" ]]; then
    analyze_devices_file "${now_epoch}" "${now_iso}" "${DEVICES_FILE}"
  fi

  prune_history "${min_epoch}"
  render_table "${now_epoch}" "${min_epoch}"

  echo
  printf 'Resume execution courante: OK=%d INFO=%d WARN=%d ERROR=%d CRITICAL=%d\n' \
    "${CURRENT_OK}" "${CURRENT_INFO}" "${CURRENT_WARN}" "${CURRENT_ERROR}" "${CURRENT_CRITICAL}"
  echo "Codes de sortie: 0=OK, 1=erreurs, 2=critiques"

  if (( CURRENT_CRITICAL > 0 )); then
    exit 2
  fi
  if (( CURRENT_ERROR > 0 )); then
    exit 1
  fi
  exit 0
}

main "$@"
