#!/bin/bash

if  [ -f ".repo/local_manifests/roomservice.xml" ]; then
    rm .repo/local_manifests/roomservice.xml
fi

oems="asus xiaomi realme motorola miromax wingtech oneplus lenovo samsung google"
for device in $oems; do
    if [[ -d device/$device ]]; then rm -rf device/$device; fi
    if [[ -d kernel/$device ]]; then rm -rf kernel/$device; fi
    if [[ -d vendor/$device ]]; then rm -rf vendor/$device; fi
done

if [[ -d "vendor/google" ]]; then 
    rm -rf vendor/google
fi

if [ -d "evolution/OTA" ]; then
    rm -rf evolution/OTA
fi

cd vendor/gms
git reset HEAD --hard
cd /evo-10
