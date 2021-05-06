#!/bin/bash

eclypsium_script="eclypsium_agent_deployer.run"
provisioner_script="hirs-provisioner"
allcomponents_script="/opt/paccor/scripts/allcomponents.sh"
allcomponents_output_file="system.json"
collator_host="collator.sca.nccoe.org"
collator_path="/upload"

# Script to scan and register computing device in the Eclypsium service from Centos7 network boot environment

# Change the hostname to something more helpful, while in the Eclypsium dashboard
ProductName=`dmidecode --string='system-product-name'`
SerialNumber=`dmidecode --string='system-serial-number'`

echo "Changing hostname to $SerialNumber$ProductName"
hostnamectl set-hostname "$SerialNumber$ProductName"

echo "Scanning and registering client device to Eclypsium..."
UUID=`dmidecode -s system-uuid`
bash "$eclypsium_script -- --run -s1 demo-0124.eclypsium.cloud sec6pHdBTOFgihZ8utdlSjeDmX6n_XHqN6kQANsbNS668k -disable-cert-verification -medium -custom-id $UUID"

echo "Running the HIRS ACA provisioner..."
bash "$provisioner_script -p"

echo "Exporting the system and component data..."
bash "$allcomponents_script > $allcomponents_output_file"

echo "Pushing system and component data to collator..."
curl -F "jsonFile=@$allcomponents_output_file" -F "UUID=$UUID" http://$collator_host$collator_path 


