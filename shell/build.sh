#!/bin/bash

device=$1

target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)

export EVO_BUILD_TYPE=Official
export CCACHE_DIR="/media/out/.ccache"
export CCACHE_MAXSIZE=70G

echo " "
echo " "
echo "Exporting RBE vars"
# RBE
export USE_RBE=1

export RBE_CXX_EXEC_STRATEGY=local
export RBE_D8_EXEC_STRATEGY=local
export RBE_JAVAC_EXEC_STRATEGY=local
export RBE_METALAVA_EXEC_STRATEGY=local
export RBE_R8_EXEC_STRATEGY=local
export RBE_RUST_EXEC_STRATEGY=local

export RBE_CXX=1
export RBE_D8=1
export RBE_JAVAC=1
export RBE_METALAVA=1
export RBE_R8=1
export RBE_RUST=1

export RBE_instance=evolutionx
export RBE_service=127.0.0.1:9092
export RBE_service_no_security=true
export RBE_service_no_auth=true
export RBE_DIR=prebuilts/remoteexecution-client/live

echo " "
echo " "
echo "Building EvolutionX for $device"
echo "------------------------------------------"

source build/envsetup.sh &&
lunch lineage_$device-$target-userdebug &&
m evolution -j48
