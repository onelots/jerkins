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
  tonuke+=" device/xiaomi/msm8996-common device/xiaomi/scorpio device/xiaomi/tissot device/xiaomi/msm8953-common"
  tonuke+=" vendor/xiaomi/msm8996-common vendor/xiaomi/scorpio vendor/xiaomi/tissot vendor/xiaomi/msm8953-common"
  tonuke+=" kernel/xiaomi/msm8996 kernel/xiaomi/msm8953"
fi

if [[ "$device" == "scorpio" ]]; then
  tonuke+=" device/xiaomi/vince device/xiaomi/msm8953-common device/xiaomi/tissot"
  tonuke+=" vendor/xiaomi/vince vendor/xiaomi/msm8953-common vendor/xiaomi/tissot"
  tonuke+=" kernel/xiaomi/vince kernel/xiaomi/msm8953"
fi

if [[ "$device" == "tissot" ]]; then
  tonuke+=" device/xiaomi/vince device/xiaomi/scorpio device/xiaomi/msm8996-common"
  tonuke+=" vendor/xiaomi/vince vendor/xiaomi/scorpio vendor/xiaomi/msm8996-common"
  tonuke+=" kernel/xiaomi/vince kernel/xiaomi/msm8996"
fi

if [[ "$device" == "beryllium" ]]; then
  tonuke+=" device/xiaomi/camera"
  tonuke+=" vendor/xiaomi/camera"
fi

# If testing device : nuke all local manifests (else it's a mess)
if [[ "$device" =~ ^(starlte|crownlte|star2lte|tissot)$ ]]; then
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