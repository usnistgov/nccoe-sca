#!/bin/bash

eclypsium_script="eclypsium_agent_deployer.run"
eclypsium_build_script="scl enable devtoolset-9 ./eclypsium_agent_builder-2.8.1.run"
eclypsium_script_host="hirs-aca.lab.nccoe.org"
eclypsium_script_path_vm="/Eclypsium_VM/"
eclypsium_script_path_dell="/Eclypsium_Dell_Laptop/"
eclypsium_script_path_hpinc="/Eclypsium_HPInc_Laptop/"
eclypsium_script_final_url=""
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
    #echo "Pushing Seagate component data to collator..."
    #curl -F "jsonFile=@$fw_attestation_output_file$drive.json" -F "UUID=$UUID" -F "type=$seagate_component" http://$collator_host$collator_path
    echo "Pushing Seagate firmware hash data to collator..."
    curl -F "jsonFile=@$fw_attestation_output_file$drive.json" -F "UUID=$UUID" -F "type=$seagate_fw_hash" http://$collator_host$collator_path
    echo "Pushing Seagate atttestation data to collator..."
    curl -F "jsonFile=@$fw_attestation_output_file$drive.json" -F "UUID=$UUID" -F "type=$seagate_fw_attestation" http://$collator_host$collator_path
done