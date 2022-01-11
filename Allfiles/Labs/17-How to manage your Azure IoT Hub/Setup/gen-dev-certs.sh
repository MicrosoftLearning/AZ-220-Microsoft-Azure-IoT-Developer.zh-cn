#!/bin/bash

# Generate 9 device certificates
# Rename for each device
# download from the Cloud CLI
pushd ~/certificates
for i in {1..9}
do
    chmod +w ./certs/new-device.cert.pem
    ./certGen.sh create_device_certificate sensor-thl-200$i
    sleep 5
    cp ./certs/new-device.cert.pfx ./certs/sensor-thl-200$i.cert.pfx
    download ./certs/sensor-thl-200$i.cert.pfx
done
popd
