#!/bin/bash

# Defines all our useful variables
device=$1
device_capitalized=$(echo $device | sed -E 's/(^|_)([a-z])/\1\u\2/g')
user=$2
host=$3
private_key=$4

# Extract Android Version from json
filename=$(echo out/target/product/$device/EvolutionX-*.zip)

android_version=$(echo "$filename" | cut -d "-" -f 2 | cut -d "." -f 1)
build_date=$(echo $filename | cut -d "-" -f 3)
evo_version=$(echo $filename | cut -d "-" -f 5)
evo_version_official=${evo_version}"-Official" 

# Upload main rom
echo "Uploading main rom..."
rclone copy out/target/product/$device/EvolutionX*.zip cloudflare-onelots:evolution-x/testers/${device_capitalized}/${android_version}/${evo_version_official}/${build_date} -P

# Upload sha256sum file
rclone copy out/target/product/$device/EvolutionX*.zip.sha256sum cloudflare-onelots:evolution-x/testers/${device_capitalized}/${android_version}/${evo_version_official}/${build_date} -P

# Upload Json
rclone copy out/target/product/$device/$device.json cloudflare-onelots:evolution-x/testers/jsons -P
                 
echo " "

# Identify and upload initial install images
json="evolution/OTA/builds/$device.json"

# Extract initial_installation_images from json
initial_images=$(jq -r '.response[0].initial_installation_images[]' "$json")

# Upload found images
for image in $initial_images; do
    echo "Uploading $image..."
    rclone copy out/target/product/$device/$image.img cloudflare-onelots:evolution-x/testers/${device_capitalized}/${android_version}/${evo_version_official}/${build_date} -P
    echo " "
done

echo "https://evox.onelots.fr/testers?path=${device_capitalized}/${android_version}/${evo_version_official}/${build_date}" > /tmp/upload_link.txt
