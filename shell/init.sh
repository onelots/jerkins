#!/bin/bash

evoVersion="$1"

if [[ "$evoVersion" == "10" ]]; then
    branch="vic"
elif [[ "$evoVersion" == "11" ]]; then
    branch="bka"
elif [[ "$evoVersion" == "12" ]]; then
    branch="cnb"
else
    echo "Usage: $0 10|11"
    exit 1
fi

echo " "
echo "----------------------------------------------------"
echo "Pull Bazel-remote from github releases"
echo "----------------------------------------------------"

rm -rf bin/bazel-remote
wget https://github.com/buchgr/bazel-remote/releases/download/v2.6.1/bazel-remote-2.6.1-linux-amd64 -O bin/bazel-remote
chmod +x bin/bazel-remote

echo "----------------------------------------------------"
echo "bazel-remote initialized, syncing EvolutionX"
echo "----------------------------------------------------"

source build/envsetup.sh
repo init -u https://github.com/Evolution-X/manifest -b "$branch" --git-lfs
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags

echo " "
echo "----------------------------------------------------"
echo "Repo synced for EvolutionX : $evoVersion version"
echo "----------------------------------------------------"