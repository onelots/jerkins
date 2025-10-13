#!/usr/bin/env bash
set -euo pipefail

ROOMSERVICE=".repo/local_manifests/roomservice.xml"

nuke() {
  [[ -f "$ROOMSERVICE" ]] || return 0
  cp -f "$ROOMSERVICE" "${ROOMSERVICE}.bak"
  for raw in "$@"; do
    [[ -n "$raw" ]] || continue
    [[ "$raw" != */* ]] && needle="${raw//_//}" || needle="$raw"
    pat="$(printf '%s' "$needle" | sed 's/[.[\*^$\/&]/\\&/g')"
    sed -i "/$pat/d" "$ROOMSERVICE"
  done
}

device="${1:?}"
tonuke=""

if [[ "$device" == "vince" ]]; then
  tonuke+=" device/xiaomi/msm8996-common device/xiaomi/scorpio"
  tonuke+=" vendor/xiaomi/msm8996-common vendor/xiaomi/scorpio"
  tonuke+=" kernel/xiaomi/msm8996"
fi

if [[ "$device" == "scorpio" ]]; then
  tonuke+=" device/xiaomi/vince"
  tonuke+=" vendor/xiaomi/vince"
  tonuke+=" kernel/xiaomi/msm8953"
fi

# If testing device : nuke all local manifests (else it's a mess)
if [[ "$device" =~ ^(starlte|crownlte|star2lte)$ ]]; then
  local_manifest+=" .repo/local_manifests/starlte.xml"
  local_manifest+=" .repo/local_manifests/star2lte.xml"
  local_manifest+=" .repo/local_manifests/crownlte.xml"
  tonuke+="$local_manifest"
fi

echo " "
echo " "
echo " ----------------------------------------------------------"
echo "Those repos will be removed: $tonuke"
echo " ----------------------------------------------------------"
echo " "
nuke $tonuke
rm -rf $tonuke