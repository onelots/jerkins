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

if [ ! -f "bin/bazel-remote" ]; then
    wget "https://github.com/buchgr/bazel-remote/releases/download/v2.6.1/bazel-remote-2.6.1-linux-amd64" -O bin/bazel-remote
    chmod +x bin/bazel-remote
fi

echo " "
echo "----------------------------------------------------"
echo "Write systemd service if not existing yet"
echo "----------------------------------------------------"

SERVICE_FILE="$HOME/.config/systemd/user/bazel-remote.service"

if [ ! -f "$SERVICE_FILE" ]; then
    mkdir -p "$(dirname "$SERVICE_FILE")"
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=bazel-remote

[Service]
Type=idle
Restart=on-failure
RestartSec=5s
Environment=BAZEL_REMOTE_DIR=.bazel-remote
Environment=BAZEL_REMOTE_MAX_SIZE=50
Environment=BAZEL_REMOTE_ZSTD_IMPLEMENTATION=cgo
Environment=BAZEL_REMOTE_HTTP_ADDRESS=127.0.0.1:9091
Environment=BAZEL_REMOTE_GRPC_ADDRESS=127.0.0.1:9092
ExecStart=bin/bazel-remote
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now bazel-remote
fi

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