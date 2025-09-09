#!/bin/bash

echo $(date +%s) > /tmp/timestamp

device=$1
target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)

source build/envsetup.sh &&
lunch lineage_$device-$target-userdebug &&
repo sync "${@:2}"