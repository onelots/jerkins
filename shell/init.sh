#!/bin/bash

evoVersion="$1"

if [[ "$evoVersion" == "10" ]]; then
    branch="vic"
elif [[ "$evoVersion" == "11" ]]; then
    branch="bka"
else
    echo "Usage: $0 10|11"
    exit 1
fi

source build/envsetup.sh
repo init -u https://github.com/Evolution-X/manifest -b "$branch" --git-lfs
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags
