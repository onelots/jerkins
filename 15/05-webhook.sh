#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Defaults
# ---------------------------
USERNAME="EvolutionX's Jenkins"
AVATAR_URL="https://images.seeklogo.com/logo-png/27/1/jenkins-logo-png_seeklogo-273560.png"
FOOTER_ICON="https://styles.redditmedia.com/t5_2385xr/styles/communityIcon_f066t3qkm4c71.png"
FOOTER_TEXT="Build launched by"
COLOR_SUCCESS=3066993    
COLOR_FAILURE=15548997   
COLOR_WARNING=16426522    
COLOR_INFO=3447003

WEBHOOK_URL=""
STATUS="info"
DEVICE=""
STARTER=""
ROM_VERSION=""
BUILD_FORMAT=""
BUILD_TYPE=""
NODE=""
BUILD_URL=""
JSON_URL=""
TXT_URL=""
VERBOSE=0
DRY_RUN=0

# ---------------------------
# Helpers
# ---------------------------
usage() {
  cat <<'USAGE'
Usage:
  ./05-webhook.sh --webhook-url URL --status <success|failure|warning|info> \
    --device DEVICE [--time T] \
    [--starter NAME] [--rom-version V] [--build-format F] [--build-type T] [--node N] \
    [--build-url URL] [--json-url URL] [--txt-url URL] [--username NAME] \
    [--avatar-url URL] [--footer-icon URL] [--verbose] [--dry-run]

Notes:
  - HTTP 204 = Success. Anything else is an error.
  - --dry-run prints a json payload without sending it.
USAGE
}

# -------------------------------------------------
# Getting the time it took to build
# -------------------------------------------------

NOW=$(date +%s)
START=$(cat /tmp/timestamp 2>/dev/null || echo "$NOW")
ELAPSED=$((NOW-START))
[ "$ELAPSED" -lt 0 ] && ELAPSED=0

H=$((ELAPSED/3600))
M=$(((ELAPSED%3600)/60))
S=$((ELAPSED%60))

is_url() {
  case "$1" in
    http://*|https://*) return 0 ;;
    *) return 1 ;;
  esac
}

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

build_description() {
  local lines=()

  if [[ -n "$BUILD_URL" && $(is_url "$BUILD_URL" && echo ok) == "ok" ]]; then
    lines+=("• 🔽 Download: [Build]($BUILD_URL)")
  fi
  if [[ -n "$JSON_URL" && $(is_url "$JSON_URL" && echo ok) == "ok" ]]; then
    lines+=("• 🧾 Json: [Artifact]($JSON_URL)")
  fi
  if [[ -n "$TXT_URL" && $(is_url "$TXT_URL" && echo ok) == "ok" ]]; then
    lines+=("• 📄 Changelog: [TXT file]($TXT_URL)")
  fi
  lines+=("• 🗂️ logs : [logs link](https://build.onelots.fr/job/10.X%20-%20A15%20-%20Testing/job/${DEVICE}/lastBuild/console)")

  if [[ ${#lines[@]} -gt 0 ]]; then
    lines+=(" ")
    lines+=("~~────────────────────────────~~")
  fi

  [[ -n "$DEVICE"      ]] && lines+=("• 📱 Device: \`$DEVICE\`")
  H=${H:-0}; M=${M:-0}; S=${S:-0}

  if (( H == 0 && M == 0 )); then
    lines+=( "• ⏱️ Time elapsed : **${S}** seconds" )
  elif (( H == 0 )); then
    lines+=( "• ⏱️ Time elapsed : **${M}** minutes and **${S}** seconds" )
  else
    lines+=( "• ⏱️ Time elapsed : **${H}** hours, **${M}** minutes and **${S}** seconds." )
  fi

  [[ -n "$ROM_VERSION" ]] && lines+=("• 📦 EvolutionX version: \`$ROM_VERSION\`")
  [[ -n "$BUILD_FORMAT" ]] && lines+=("• 🧹 Format: \`$BUILD_FORMAT\`")
  [[ -n "$BUILD_TYPE"  ]] && lines+=("• 🧑‍💻 Type: \`$BUILD_TYPE\`")
  [[ -n "$NODE"        ]] && lines+=("• 🖥️ Node: \`$NODE\`")

  local IFS=$'\n'
  printf '%s' "${lines[*]}"
}

build_payload() {
  local status_lc title color description embed_url footer_text
  status_lc="$(lc "$STATUS")"

  case "$status_lc" in
    success|ok|SUCCESS)         title=" Build Successful ✅";   color=$COLOR_SUCCESS ;;
    failure|fail|error|failed|FAIL) title=" Build failed ❌";   color=$COLOR_FAILURE ;;
    warning|unstable)   title="⚠️ Build unstable"; color=$COLOR_WARNING ;;
    *)                  title="ℹ️ Build";         color=$COLOR_INFO ;;
  esac

  [[ -n "$DEVICE" ]] && title="$DEVICE: $title"

  description="$(build_description)"
  embed_url=""
  if [[ -n "$BUILD_URL" && $(is_url "$BUILD_URL" && echo ok) == "ok" ]]; then
    embed_url="$BUILD_URL"
  fi

  footer_text="$FOOTER_TEXT"
  [[ -n "$STARTER" ]] && footer_text="$FOOTER_TEXT $STARTER"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$title" "$description" "$embed_url" "$color" "$USERNAME" "$AVATAR_URL" "$footer_text" "$FOOTER_ICON" <<'PY'
import json, sys
title, description, embed_url, color, username, avatar, footer_text, footer_icon = sys.argv[1:]
payload = {
  "content": "",
  "username": username,
  "avatar_url": avatar,
  "embeds": [{
    "title": title,
    "description": description,
    "color": int(color),
    "footer": { "text": footer_text, "icon_url": footer_icon }
  }]
}
if embed_url:
  payload["embeds"][0]["url"] = embed_url
print(json.dumps(payload, ensure_ascii=False))
PY
  else
    esc_json() {
      awk 'BEGIN{ORS="";}{
        gsub(/\\/,"\\\\",$0);
        gsub(/"/,"\\\"",$0);
        gsub(/\t/,"\\t",$0);
        gsub(/\r/,"\\r",$0);
        gsub(/\n/,"\\n",$0);
        print $0
      }' <<<"$1"
    }
    local title_e desc_e footer_e user_e avatar_e icon_e url_line=""
    title_e="$(esc_json "$title")"
    desc_e="$(esc_json "$description")"
    user_e="$(esc_json "$USERNAME")"
    avatar_e="$(esc_json "$AVATAR_URL")"
    footer_e="$(esc_json "$footer_text")"
    icon_e="$(esc_json "$FOOTER_ICON")"
    if [[ -n "$embed_url" ]]; then
      url_line=",\n      \"url\": \"$(esc_json "$embed_url")\""
    fi
    cat <<EOF
{
  "content": "",
  "username": "$user_e",
  "avatar_url": "$avatar_e",
  "embeds": [
    {
      "title": "$title_e",
      "description": "$desc_e",
      "color": $color$url_line,
      "footer": { "text": "$footer_e", "icon_url": "$icon_e" }
    }
  ]
}
EOF
  fi
}

send_webhook() {
  local payload tmp code tries=0 max_tries=3
  payload="$(build_payload)"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "---- DRY RUN: payload ----"
    echo "$payload"
    echo "---- /payload ----"
    return 0
  fi

  tmp="$(mktemp)"
  while :; do
    if [[ $VERBOSE -eq 1 ]]; then
      code="$(curl -v -sS -o "$tmp" -w "%{http_code}" \
        -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL")"
    else
      code="$(curl -sS -o "$tmp" -w "%{http_code}" \
        -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL")"
    fi

    if [[ "$code" == "204" || "$code" == "200" ]]; then
      echo "OK ($code) — Webhook sent."
      rm -f "$tmp"
      return 0
    fi

    if [[ "$code" == "429" && $tries -lt $max_tries ]]; then
      tries=$((tries+1))
      local ms=1000
      if command -v jq >/dev/null 2>&1; then
        ms="$(jq -r '.retry_after // 1000' "$tmp" 2>/dev/null || echo 1000)"
      else
        ms="$(sed -n 's/.*"retry_after":[[:space:]]*\([0-9]\+\).*/\1/p' "$tmp" | head -n1)"
        ms="${ms:-1000}"
      fi
      local sleep_secs
      sleep_secs=$(awk "BEGIN{print $ms/1000}")
      echo "429 — Rate limited. Retry in ${sleep_secs}s (tentative $tries/$max_tries)…"
      sleep "$sleep_secs"
      continue
    fi

    echo "ERROR HTTP $code while sending the webhook."
    echo "Discord reply:"
    cat "$tmp"; echo
    rm -f "$tmp"
    return 1
  done
}

# ---------------------------
# Arg parsing (long options)
# ---------------------------
if [[ $# -eq 0 ]]; then usage; exit 1; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --webhook-url)   WEBHOOK_URL="$2"; shift 2 ;;
    --status)        STATUS="$2"; shift 2 ;;
    --device)        DEVICE="$2"; shift 2 ;;
    -T| --time)      TIME="${2:-0}"; shift 2 ;;
    --starter)       STARTER="$2"; shift 2 ;;
    --rom-version)   ROM_VERSION="$2"; shift 2 ;;
    --build-format)  BUILD_FORMAT="$2"; shift 2 ;;
    --build-type)    BUILD_TYPE="$2"; shift 2 ;;
    --node)          NODE="$2"; shift 2 ;;
    --build-url)     BUILD_URL="$2"; shift 2 ;;
    --json-url)      JSON_URL="$2"; shift 2 ;;
    --txt-url)       TXT_URL="$2"; shift 2 ;;
    --username)      USERNAME="$2"; shift 2 ;;
    --avatar-url)    AVATAR_URL="$2"; shift 2 ;;
    --footer-icon)   FOOTER_ICON="$2"; shift 2 ;;
    --verbose)       VERBOSE=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Option inconnue: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "Erreur: --webhook-url is missing"; exit 1
fi
if ! is_url "$WEBHOOK_URL"; then
  echo "Erreur: --webhook-url needs to start by https"; exit 1
fi

if [[ -n "$STARTER" ]]; then
  FOOTER_TEXT="$FOOTER_TEXT $STARTER"
fi

send_webhook
