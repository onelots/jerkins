#!/bin/bash

device=$1

target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)

export CCACHE_MAXSIZE=50G

. build/envsetup.sh

lunch lineage_$device-$target-user

# Generate Vendor
bash ./lineage/scripts/pixel/device.sh $device

# Remove duplicates in vendor/google and vendor/gms
SOURCE_PATH="vendor/gms/product/packages/privileged_apps/"
TARGET_ROOT="vendor/google"
TARGET_SUBPATH="proprietary/product/priv-app"

for source_dir in "$SOURCE_PATH"/*; do
    base_name=$(basename "$source_dir")

    target_dirs=$(find "$TARGET_ROOT" -type d -path "*/$TARGET_SUBPATH/$base_name")

    if [[ -n "$target_dirs" ]]; then
        echo "Match found for $base_name in $TARGET_ROOT.  Removing $source_dir..."
        rm -rf "$source_dir"
    else
        echo "No match found for $base_name. Keeping $source_dir."
    fi
done
