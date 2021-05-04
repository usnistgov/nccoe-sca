#!/bin/bash

# Script to scan and register computing device in the Eclypsium service from Centos7 network boot environment

# Change the hostname to something more helpful, while in the Eclypsium dashboard

ProductName=`dmidecode --string='system-product-name'`
SerialNumber=`dmidecode --string='system-serial-number'`

echo "Changing hostname to $SerialNumber$ProductName"
hostnamectl set-hostname "$SerialNumber$ProductName"

echo "Scanning and registering client device to Eclypsium..."
UUID=`dmidecode -s system-uuid`
./eclypsium_agent_deployer.run -- --run -s1 demo-0124.eclypsium.cloud  sec6pHdBTOFgihZ8utdlSjeDmX6n_XHqN6kQANsbNS668k -disable-cert-verification -medium -custom-id $UUID
