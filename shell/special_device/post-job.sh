#!/usr/bin/env bash
set -euo pipefail

device="${1}"
evo_version="${2}"

source build/envsetup.sh &&

echo "Post-job script for special device: $device"

if [[ "${device}" =~ ^(cheeseburger|dumpling)$ ]]; then

echo "cleaning script for special device: $device"

# Qcom-caf common
repo sync --force-sync hardware/qcom-caf/common

# Vendor qcom opensource commonsys-intf display
repo sync --force-sync vendor/qcom/opensource/commonsys-intf/display

# Sepolicy legacy
repo sync --force-sync device/qcom/sepolicy-legacy-um

fi