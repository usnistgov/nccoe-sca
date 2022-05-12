#!/bin/bash

tscverify="TSCVerifyUtil"
dpd_output_file="DPDOutput.xml"
seagate_drive_array=("sg1" "sg2" "sg3")
fw_attestation_output_file="Tper_FW_Message_JSON_"
output_directory="out"
collator_host="<HOSTNAME>"
collator_path="/api/upload"
collator_xmlpath="/api/uploadXML"
UUID=`dmidecode -s system-uuid`
seagate_fw_hash="Seagate.FW.Hash"
seagate_fw_attestation="Seagate.FW.Attestation"
seagate_component="Seagate.Component"
intel_server="Intel.Server"


# TODO: Eclypsium


mkdir -p $output_directory

# Only scanning until new DPD file can be generated
echo "Scanning server and comparing Direct Platform Data using TSCVerifyUtil..."
$tscverify SCANWRITE -d $output_directory -fl $dpd_output_file

echo "Pushing server platform manifest to the collator..."
curl -F "XMLFile=@$dpd_output_file" -F "UUID=$UUID" -F "type=$intel_server" http://$collator_host$collator_xmlpath

echo "Detected ${#seagate_drive_array[@]} Seagate Drives"
for drive in ${seagate_drive_array[@]}; do
  echo "Running TSCVerify on Seagate drive $drive"
  $tscverify DRIVEATTEST -d $drive > "$output_directory/$tscverify.txt" 2>&1
  # exit script if provisioning was not successful
    if [ $? -ne 0 ]; then
            echo "Seagate firmware attestation failed. Exiting script"
            exit 1
    fi

    echo "Pushing Seagate firmware hash data to collator..."
    curl -F "jsonFile=@$fw_attestation_output_file$drive.json" -F "UUID=$UUID" -F "type=$seagate_fw_hash" http://$collator_host$collator_path
    echo "Pushing Seagate atttestation data to collator..."
    curl -F "jsonFile=@$fw_attestation_output_file$drive.json" -F "UUID=$UUID" -F "type=$seagate_fw_attestation" http://$collator_host$collator_path
done