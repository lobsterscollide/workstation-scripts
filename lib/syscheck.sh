#!/usr/bin/env bash
# syscheck.sh — shared helpers for startup / update / scan / audit
# Source this file, do not execute it directly.

BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
# shellcheck disable=SC2034  # used by the scripts that source this file
DIM='\033[2m'
RESET='\033[0m'

NOTES=()
ERRORS=()
TOTAL_STEPS=0
STEP=0

LOG_DIR="${HOME}/.local/var/log/security"
HARDENED_API_URL="${HARDENED_API_URL:-http://localhost:8080}"

# Call at the start of a scan script to tee all output to a timestamped log file.
# Usage: init_log scan   → ~/.local/var/log/security/scan-2026-04-08T10:55:00.log
init_log() {
  local name="${1:-scan}"
  mkdir -p "$LOG_DIR" && chmod 700 "$LOG_DIR"
  umask 077
  LOG_FILE="${LOG_DIR}/${name}-$(date '+%Y-%m-%dT%H:%M:%S').log"
  # Tee stdout+stderr to log file, stripping ANSI colour codes in the file copy
  exec > >(tee >(sed 's/\x1b\[[0-9;]*[mGKHF]//g' >> "$LOG_FILE")) 2>&1
  echo "# ${name} — $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
}

note()  { NOTES+=("$1"); }
fail()  { ERRORS+=("$1"); }
ok()    { echo -e "  ${GREEN}✓${RESET}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $1"; note "$1"; }
err()   { echo -e "  ${RED}✗${RESET}  $1"; fail "$1"; }

progress() {
  STEP=$((STEP + 1))
  local label="$1"
  local filled=$(( STEP * 20 / TOTAL_STEPS ))
  local empty=$(( 20 - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo -e "\n${BOLD}${CYAN}[${bar}] (${STEP}/${TOTAL_STEPS}) ${label}${RESET}"
}

summary() {
  echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  if [[ ${#ERRORS[@]} -eq 0 && ${#NOTES[@]} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All clear.${RESET}"
  else
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
      echo -e "${RED}${BOLD}Errors (${#ERRORS[@]}):${RESET}"
      for e in "${ERRORS[@]}"; do echo -e "  ${RED}✗${RESET}  $e"; done
    fi
    if [[ ${#NOTES[@]} -gt 0 ]]; then
      echo -e "${YELLOW}${BOLD}Needs attention (${#NOTES[@]}):${RESET}"
      for n in "${NOTES[@]}"; do echo -e "  ${YELLOW}⚠${RESET}  $n"; done
    fi
  fi
  echo ""
}
