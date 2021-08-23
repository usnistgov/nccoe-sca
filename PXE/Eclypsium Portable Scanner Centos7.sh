#!/bin/bash

eclypsium_script="./eclypsium_agent_deployer.run"
eclypsium_build_script="./eclypsium.run"
provisioner_script="hirs-provisioner"
allcomponents_script="/opt/paccor/scripts/allcomponents.sh"
allcomponents_output_file="system.json"
collator_host="collator.lab.nccoe.org"
collator_path="/upload"

# Script to scan and register computing device in the Eclypsium service from Centos7 network boot environment

# Change the hostname to something more helpful, while in the Eclypsium dashboard
ProductName=`dmidecode --string='system-product-name'`
SerialNumber=`dmidecode --string='system-serial-number'`
VMWARE="VMware Virtual Platform"

echo "Changing hostname to $SerialNumber$ProductName"
hostnamectl set-hostname "$SerialNumber$ProductName"

UUID=`dmidecode -s system-uuid`
if [ "$ProductName" != "$VMWARE" ]; then
	echo "Building the Eclypsium scanner..."
	$eclypsium_build_script
	echo "Scanning and registering client device to Eclypsium..."
	$eclypsium_script -- --run -s1 demo-0124.eclypsium.cloud secxvhI545Es4gj1eud1S4c38UI2NBkmjFmEylx4HLnYFE -ca-cert-path /etc/pki/tls/certs/ca-bundle.crt -medium -custom-id $UUID
else
	echo "VM detected, skipping Eclypsium registration"
fi

echo "Running the HIRS ACA provisioner..."
$provisioner_script -p

# exit script if provisioning was not successful
if [ $? -ne 0 ]; then
	echo "HIRS ACA provisioning failed. Exiting script"
	exit 1
fi

echo "Exporting the system and component data..."
$allcomponents_script > $allcomponents_output_file

echo "Pushing system and component data to collator..."
curl -F "jsonFile=@$allcomponents_output_file" -F "UUID=$UUID" -F "type=HIRS" http://$collator_host$collator_path 
