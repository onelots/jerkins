#!/bin/bash

device=$1

target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)

export CCACHE_DIR="/media/out/.ccache"
export CCACHE_MAXSIZE=70G

source build/envsetup.sh &&
lunch lineage_$device-$target-userdebug &&
m installclean
