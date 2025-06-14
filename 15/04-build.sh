#!/bin/bash

device=$1

target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)

export EVO_BUILD_TYPE=Official
export CCACHE_MAXSIZE=50G

source build/envsetup.sh &&
lunch lineage_$device-$target-user &&
m evolution
