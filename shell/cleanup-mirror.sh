#!/bin/bash

rm -rf /root/Testers/
mkdir /root/Testers/

version=$1

devices="Sargo Bonito Crosshatch Blueline Cheeseburger Dumpling Ginkgo Guacamole Guacamoleb Hotdog Hotdogb Miatoll Laurel_Sprout Veux Vince Scorpio Polaris"
for device in $devices; do
    mkdir /root/Testers/$device
    mkdir /root/Testers/$device/$version     
done