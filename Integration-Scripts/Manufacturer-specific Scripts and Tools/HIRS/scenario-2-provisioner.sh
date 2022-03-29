#!/bin/bash

eclypsium_script="eclypsium_agent_deployer.run"
eclypsium_build_script="scl enable devtoolset-9 ./eclypsium_agent_builder-2.8.1.run"
eclypsium_script_host="hirs-aca.lab.nccoe.org"
eclypsium_script_path_vm="/Eclypsium_VM/"
eclypsium_script_path_dell="/Eclypsium_Dell_Laptop/"
eclypsium_script_path_hpinc="/Eclypsium_HPInc_Laptop/"
eclypsium_script_final_url=""
provisioner_script="hirs-provisioner"
allcomponents_script="/opt/paccor/scripts/allcomponents.sh"
allcomponents_output_file="system.json"
collator_host="collator.lab.nccoe.org"
collator_path="/api/upload"

# Script to scan and register computing device in the Eclypsium service from Centos7 network boot environment

# Change the hostname to something more helpful, while in the Eclypsium dashboard
ProductName=`dmidecode --string='system-product-name'`
SerialNumber=`dmidecode --string='system-serial-number'`
UUID=`dmidecode -s system-uuid`

VMWARE="VMware Virtual Platform"
QEMU="Standard PC (Q35 + ICH9, 2009)"
HPINC1="HP EliteBook 840 G7 Notebook PC"
HPINC2="HP ZBook Firefly 14 G7 Mobile Workstation"
DELL6="Latitude 5520" #dell-8 is the same model

echo "Changing hostname to $SerialNumber$ProductName"
hostnamectl set-hostname "$SerialNumber$ProductName"



if [ "$ProductName" = "$QEMU" ]; then
        eclypsium_script_final_url="http://$eclypsium_script_host$eclypsium_script_path_vm$eclypsium_script"
elif [ "$ProductName" = "$DELL6" ]; then
        eclypsium_script_final_url="http://$eclypsium_script_host$eclypsium_script_path_dell$eclypsium_script"
elif [ "$ProductName" = "$HPINC1" ] || [ "$ProductName" = "$HPINC2" ]; then
        eclypsium_script_final_url="http://$eclypsium_script_host$eclypsium_script_path_hpinc$eclypsium_script"
fi

if [ "$ProductName" = "$VMWARE" ]; then
	echo "VMWare detected, skipping Eclypsium registration"
else
	echo "Detected $ProductName"
	echo "Downloading the precompiled Eclypsium for this platform ..."
	wget $eclypsium_script_final_url
	chmod +x $eclypsium_script
	echo "Scanning and registering client device to Eclypsium..."
	./$eclypsium_script -- --run -s1 demo-0124.eclypsium.cloud secxvhI545Es4gj1eud1S4c38UI2NBkmjFmEylx4HLnYFE -ca-cert-path /etc/pki/tls/certs/ca-bundle.crt -medium -custom-id $UUID
                
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
