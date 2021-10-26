#!/bin/bash

hpe_script="./platform_verification.sh"
collator_host="collator.lab.nccoe.org"
collator_path="/api/upload"
manifest_file="tmp/HPE_hardware_manifest.json"

# Script to scan and register computing device in the Eclypsium service from Centos7 network boot environment

# Change the hostname to something more helpful, while in the Eclypsium dashboard
ProductName=`dmidecode --string='system-product-name'`
SerialNumber=`dmidecode --string='system-serial-number'`
VMWARE="VMware Virtual Platform"


UUID=`dmidecode -s system-uuid`
if [ "$ProductName" != "$VMWARE" ]; then
	echo "$ProductName detected"
else
        echo "VM detected, skipping Eclypsium registration"
fi

echo "Running the HPE hardware validation script..."
$hpe_script

# exit script if provisioning was not successful
if [ $? -ne 0 ]; then
        echo "platform_verification script failed. Exiting script"
        exit 1
fi


echo "Pushing system and component data to collator..."
curl -F "jsonFile=@$manifest_file" -F "UUID=$UUID" -F "type=HPE" http://$collator_host$collator_path

