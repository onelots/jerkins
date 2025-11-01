#!/usr/bin/env bash
set -euo pipefail

device="${1}"
evo_version="${2}"

echo "Post-job script for special device: $device"

if [[ "$device" ~= (cheeseburger|dumpling)]]

fi