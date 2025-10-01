#!/bin/bash

echo $(date +%s) > /tmp/timestamp

device=$1
target=$(tail -n 1 vendor/lineage/vars/aosp_target_release | cut -d "=" -f 2)
toSync=""

# Taking care of OEM repos 
# Google hardware
if [[ "$device" =~ ^(blueline|bonito|crosshatch|sargo)$ ]]; then
    toSync+=" packages/apps/ElmyraService device/google/gs-common"
fi
# Oneplus hardware
if [[ "$device" =~ ^(cheeseburger|dumpling)$ ]]; then
    toSync+=" hardware/oneplus"
fi
# Oneplus (Oplus) hardware
if [[ "$device" =~ ^(guacamole|guacamoleb|hotdog|hotdogb)$ ]]; then
    toSync+=" hardware/oplus"
fi
# Xiaomi Hardware
if [[ "$device" =~ ^(beryllium|laurel_sprout|miatoll|perseus|polaris|scorpio|veux|vince|sweet)$ ]]; then
    toSync+=" hardware/xiaomi"
fi

# Now device specific repos
# Google devices : we better sync all the devices at once for same soc series. trust me.

# Blueline and Crosshatch are on same soc series (sdm845)
if [[ "$device" =~ ^(blueline|crosshatch)$ ]]; then
    toSync+=" device/google/blueline device/google/crosshatch"
    toSync+=" vendor/google/blueline vendor/google/crosshatch"
    toSync+=" kernel/google/b1c1"
    toSync+=" vendor/Camera/b1c1"
fi
# Bonito and Sargo are on same soc series as well
if [[ "$device" =~ ^(bonito|sargo)$ ]]; then
    toSync+=" device/google/bonito device/google/sargo"
    toSync+=" vendor/google/bonito vendor/google/sargo"
    toSync+=" kernel/google/b4s4"
    toSync+=" vendor/Camera/b4s4"
fi
# Xiaomi Beryllium (sdm845)
if [[ "$device" == "beryllium" ]]; then
    toSync+=" device/xiaomi/beryllium device/xiaomi/sdm845-common"
    toSync+=" vendor/xiaomi/beryllium vendor/xiaomi/sdm845-common"
    toSync+=" kernel/xiaomi/sdm845"
fi

# OnePlus 5 series => msm8998 

if [[ "$device" == "cheeseburger" ]]; then
    toSync+=" device/oneplus/cheeseburger device/oneplus/msm8998-common"
    toSync+=" vendor/oneplus/cheeseburger vendor/oneplus/msm8998-common"
    toSync+=" kernel/oneplus/msm8998"
fi
if [[ "$device" == "dumpling" ]]; then
    toSync+=" device/oneplus/dumpling device/oneplus/msm8998-common"
    toSync+=" vendor/oneplus/dumpling vendor/oneplus/msm8998-common"
    toSync+=" kernel/oneplus/msm8998"
fi

# OnePlus sm8150 Serie
if [[ "$device" == "guacamole" ]]; then
    toSync+=" device/oneplus/guacamole device/oneplus/sm8150-common"
    toSync+=" vendor/oneplus/guacamole vendor/oneplus/sm8150-common"
    toSync+=" kernel/oneplus/sm8150"
fi
if [[ "$device" == "guacamoleb" ]]; then
    toSync+=" device/oneplus/guacamoleb device/oneplus/sm8150-common"
    toSync+=" vendor/oneplus/guacamoleb vendor/oneplus/sm8150-common"
    toSync+=" kernel/oneplus/sm8150"
fi
if [[ "$device" == "hotdog" ]]; then
    toSync+=" device/oneplus/hotdog device/oneplus/sm8150-common"
    toSync+=" vendor/oneplus/hotdog vendor/oneplus/sm8150-common"
    toSync+=" kernel/oneplus/sm8150"
fi
if [[ "$device" == "hotdogb" ]]; then
    toSync+=" device/oneplus/hotdogb device/oneplus/sm8150-common"
    toSync+=" vendor/oneplus/hotdogb vendor/oneplus/sm8150-common"
    toSync+=" kernel/oneplus/sm8150"
fi

# Xiaomi Mi A3 (laurel_sprout) // TODO => add ginkgo (redmi note 8T, same soc)
if [[ "$device" == "laurel_sprout" ]]; then
    toSync+=" device/xiaomi/laurel_sprout device/xiaomi/sm6125-common"
    toSync+=" vendor/xiaomi/laurel_sprout vendor/xiaomi/sm6125-common"
    toSync+=" kernel/xiaomi/sm6125"
fi

# Xiaomi Miatoll serie
if [[ "$device" == "miatoll" ]]; then
    toSync+=" device/xiaomi/miatoll device/xiaomi/sm6250-common"
    toSync+=" vendor/xiaomi/miatoll vendor/xiaomi/sm6250-common"
    toSync+=" kernel/xiaomi/sm6250"
fi

# Other xiaomi devices (sdm845)
if [[ "$device" == "perseus" ]]; then
    toSync+=" device/xiaomi/perseus device/xiaomi/sdm845-common"
    toSync+=" vendor/xiaomi/perseus vendor/xiaomi/sdm845-common"
    toSync+=" kernel/xiaomi/sdm845"
fi

if [[ "$device" == "polaris" ]]; then
    toSync+=" device/xiaomi/polaris device/xiaomi/sdm845-common"
    toSync+=" vendor/xiaomi/polaris vendor/xiaomi/sdm845-common"
    toSync+=" kernel/xiaomi/sdm845"
fi

# Xiaomi msm8996 device 
if [[ "$device" == "scorpio" ]]; then
    toSync+=" device/xiaomi/scorpio device/xiaomi/msm8996-common"
    toSync+=" vendor/xiaomi/scorpio vendor/xiaomi/msm8996-common"
    toSync+=" kernel/xiaomi/msm8996"
fi

# Xiaomi Veux : sm6375 (for the win !!)
if [[ "$device" == "veux" ]]; then
    toSync+=" device/xiaomi/veux"
    toSync+=" device/xiaomi/camera"
    toSync+=" vendor/xiaomi/veux"
    toSync+=" vendor/xiaomi/camera"
    toSync+=" kernel/xiaomi/veux"
fi

# Xiaomi Vince : msm8953 (legends never die... Tissot incoming !)
if [[ "$device" == "vince" ]]; then
    toSync+=" device/xiaomi/vince"
    toSync+=" vendor/xiaomi/vince"
    toSync+=" kernel/xiaomi/msm8953"
fi


# NOT MY DEVICES 
# sweet is therealmharc's device

if [[ "$device" == "sweet" ]]; then
    toSync+=" device/xiaomi/sweet device/xiaomi/sm6150-common device/xiaomi/miuicamera-sweet"
    toSync+=" vendor/xiaomi/sweet vendor/xiaomi/sm6150-common vendor/xiaomi/miuicamera-sweet"
    toSync+=" kernel/xiaomi/sm6150"
    # Special package
    toSync+=" packages/apps/ViPER4AndroidFX"
fi

source build/envsetup.sh &&
lunch lineage_$device-$target-userdebug &&
repo sync $toSync
