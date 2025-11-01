#!/usr/bin/env bash
set -euo pipefail

device="${1}"
evo_version="${2}"

if [[ "${device}" =~ ^(cheeseburger|dumpling)$ ]]; then

echo "Pre-job script for special device: $device"

# Qcom-caf common
cd hardware/qcom-caf/common && \
    git cherry-pick --abort 2>/dev/null || true && \
    git fetch https://github.com/ederevx/android_hardware_qcom-caf_common a15 && \
    git cherry-pick 468cd2bae94cdf01a826ea78c53469beb2427046 && \
    cd ../../../

# Vendor qcom opensource commonsys-intf display
cd vendor/qcom/opensource/commonsys-intf/display && \
    git cherry-pick --abort 2>/dev/null || true && \
    git fetch https://github.com/ederevx/android_vendor_qcom_opensource_display-commonsys-intf lineage-22.1-msm8998-4-14 && \
    git cherry-pick 385d238cc4ec9b7802b941131ef99742e530c659^..f235461d3cd0fe015e86a9c6136e2d3cf7c392ea && \
    cd ../../../../../

# Sepolicy legacy
cd device/qcom/sepolicy-legacy-um && \
    git cherry-pick --abort 2>/dev/null || true && \
    git fetch https://github.com/ederevx/android_device_qcom_sepolicy a15 && \
    git cherry-pick bd3086d857f6c9f9f2c3461f6bead0e75f119886^..492418bf7ac1336d3c42db326ffa40c8d3ecc20d && \
    cd ../../../

else 
echo "Nothing to do !"
fi