#!/bin/bash

device=$1

# Extract Android Version from json
filename=$(echo out/target/product/$device/EvolutionX-*.zip)
version=$(echo $filename | cut -d "-" -f 2)

# Upload main rom
echo "Uploading main rom..."
rclone copy out/target/product/$device/EvolutionX*.zip b2:evo-downloads/$device/$version/
echo " "

# Identify and upload initial install images
json="evolution/OTA/builds/$device.json"

# Extract initial_installation_images from json
initial_images=$(jq -r '.response[0].initial_installation_images[]' "$json")

# Upload found images
for image in $initial_images; do
    echo "Uploading $image..."
    # Nothing for now, gotta see if it works first...
    echo " "
done
