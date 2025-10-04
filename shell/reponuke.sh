#!/bin/bash

device=$1
tonuke=""

rm -rf .repo/local_manifests/roomservice.xml

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

echo "Those repos will be remove : $tonuke"
rm -rf $tonuke