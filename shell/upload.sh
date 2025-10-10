#!/bin/bash

# -----------------------------------
# Defines all our useful variables  |
# -----------------------------------

device=$1
device_capitalized=$(echo $device | sed -E 's/(^|_)([a-z])/\1\u\2/g')
buildType=$2

# Extract Android Version from json
filename=$(echo out/target/product/$device/EvolutionX-*.zip)

# Extract date (meh how can I use $date without even defining it)
date=$(echo $filename | cut -d "-" -f 3 | cut -d "." -f 1)

android_version=$(echo "$filename" | cut -d "-" -f 2 | cut -d "." -f 1)
build_date=$(echo $filename | cut -d "-" -f 3)
evo_version=$(echo $filename | cut -d "-" -f 5)
evo_version_official=${evo_version}"-Official" 

# Identify and upload initial install images
json="evolution/OTA/builds/$device.json"
if [ -e "$json" ]; then
    echo "$json found."
    # Extract initial_installation_images from json
    initial_images=$(jq -r '.response[0].initial_installation_images[]' "$json")
    echo " "
else
    echo "Json file not found ! Processing with known base images."
    if [[ "$device" =~ ^(bonito|sargo)$ ]]; then
        initial_images="boot"
    elif [[ "$device" =~ ^(blueline|crosshatch)$ ]]; then
        initial_images="boot dtbo"
    elif [[ "$device" =~ ^(cheeseburger|dumpling)$ ]]; then # Oplus recovery only
        initial_images="recovery"
    elif [[ "$device" =~ ^(guacamole|guacamoleb)$ ]]; then
        initial_images="boot vbmeta dtbo"
    elif [[ "$device" =~ ^(hotdog|hotdogb)$ ]]; then
        initial_images="vbmeta dtbo recovery"
    elif [[ "$device" =~ ^(beryllium|perseus|polaris|scorpio|vince|miatoll)$ ]]; then
        initial_images="recovery"
    elif [[ "$device" =~ ^(laurel_sprout)$ ]]; then
        initial_images="boot"
    elif [[ "$device" =~ ^(veux)$ ]]; then
        initial_images="boot vendor_boot dtbo"
    else
        initial_images=""
    fi
fi
echo "Initial images to upload: $initial_images"
# |------------------------------------------------------------------------------------------------------------------------|

# For testing releases, by definition it's testing.
# So we didn't push any OTA; hence no json file.
# So we need to define manually what to upload.

# |----------------------------------------------------------|
# | EVOLUTIONX OFFICIAL RELEASE.                             |
# |----------------------------------------------------------|

if [ "$buildType" = "release" ]; then

    upload_path="evolution-x/downloads/${device_capitalized}/${android_version}/${evo_version_official}/${build_date}"

    # Upload main rom
    echo "Uploading main rom..."
    rclone copy out/target/product/$device/EvolutionX*.zip cloudflare-onelots:$upload_path -P
    # Upload sha256sum file
    rclone copy out/target/product/$device/EvolutionX*.zip.sha256sum cloudflare-onelots:$upload_path -P
    # Upload found images
    for image in $initial_images; do
        echo "Uploading $image..."
        rclone copy out/target/product/$device/$image.img cloudflare-onelots:$upload_path -P
        echo " "
    done
    echo "https://evox.onelots.fr/downloads?path=${device_capitalized}/${android_version}/${evo_version_official}/${build_date}" > /tmp/upload_link.txt

# |----------------------------------------------------------|
# | EVOLUTIONX OFFICIAL PART - DO NOT MODIFY ! AT ANY COST ! |
# |----------------------------------------------------------|

    # Upload main rom file 
    echo "Uploading main rom..."
    rclone copy out/target/product/$device/EvolutionX*.zip cloudflare-evo:evolution-builds/$device/$android_version/ -P

    # Upload found images
    for image in $initial_images; do
        echo "Uploading $image..."
        rclone copy out/target/product/$device/$image.img cloudflare-evo:evolution-builds/$device/$android_version/$image/ -P
        echo " "
    done

# |-------------------------------------------------------------------------------------------------------------------------------------|

elif [ "$buildType" = "testing" ]; then
    testers_path="evolution-x/testers/${device_capitalized}/${android_version}/${evo_version_official}/${build_date}"
    # Upload main rom
    echo "Uploading main rom..."
    rclone copy out/target/product/$device/EvolutionX*.zip cloudflare-onelots:$testers_path -P
    # Upload sha256sum file
    rclone copy out/target/product/$device/EvolutionX*.zip.sha256sum cloudflare-onelots:$testers_path -P
    # Upload Json
    rclone copy out/target/product/$device/$device.json cloudflare-onelots:evolution-x/testers/jsons -P      
    echo " "
    # Upload found images, defined earlier in the script
    for image in $initial_images; do
        echo "Uploading $image..."
        rclone copy out/target/product/$device/$image.img cloudflare-onelots:$testers_path -P
        echo " "
    done

    echo "https://evox.onelots.fr/testers?path=${device_capitalized}/${android_version}/${evo_version_official}/${build_date}" > /tmp/upload_link.txt

fi

