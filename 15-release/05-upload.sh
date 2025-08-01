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

# Check if folder exists
# Build_date's path (example : /root/Testers/Polaris/15/10.7/20250515/)
build_date_path=("/root/Testers/${device_capitalized}/${android_version}/${evo_version_official}/${build_date}")
ssh -o StrictHostKeyChecking=no -i ${private_key} ${user}@${host} "[ -d ${build_date_path} ] && echo 'exists' || mkdir -p  ${build_date_path}"

# Upload main rom
echo "Uploading main rom..."
scp -o StrictHostKeyChecking=no -i ${private_key} out/target/product/$device/EvolutionX*.zip ${user}@${host}:/${build_date_path}
               
echo " "

# Identify and upload initial install images
json="evolution/OTA/builds/$device.json"

# Extract initial_installation_images from json
initial_images=$(jq -r '.response[0].initial_installation_images[]' "$json")

# Upload found images
for image in $initial_images; do
    echo "Uploading $image..."
    scp -o StrictHostKeyChecking=no -i ${private_key} out/target/product/$device/$image.img ${user}@${host}:/${build_date_path}
    echo " "
done

echo "https://evox.onelots.fr/testers?path=${device_capitalized}/${android_version}/${evo_version_official}/${build_date}" > /tmp/upload_link.txt

