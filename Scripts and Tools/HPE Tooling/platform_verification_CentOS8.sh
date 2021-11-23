#!/bin/sh

#Copy the Platform Certificate from EFI
cp -n /sys/firmware/efi/efivars/HpePlatformCertificate-b250b9d5-40e6-b2bb-af7c-4f9e95a15b31 /opt/hpe/scl/HpePlatformCertificateSCLdata

#Since this is a development system, we can't perform the following. This acceptance testing image has lab certs pre-configured.
##First of all it is necessary to download the Platform Certificate, the System IDevID Certificate and the System IAK Certificate from iLO.
##This can be achieved by doing a GET request to the iLO API endpoint below filtering for the fields "PlatformCert", "SystemIDevID" and "SystemIAKCert".
##The same process can be done through the ilorest tool.


#Generate the HW manifest
java -jar pcvt-mvn-0.0.1-jar-with-dependencies.jar -genhwmanif -scl /opt/hpe/scl/HpePlatformCertificateSCLdata -o /opt/hpe/scl/HPE_hardware_manifest.json
sed -i 's/SD\/MMC_CRW/SD_MMC_CRW/' /opt/hpe/scl/HPE_hardware_manifest.json

#Run the PCVT tool against the manifest
java -jar pcvt-mvn-0.0.1-jar-with-dependencies.jar -checkplatcert -hwmanif /opt/hpe/scl/HPE_hardware_manifest.json -spc /opt/hpe/scl/certificates/PlatformCertificate.pem -iakcert /opt/hpe/scl/certificates/IAKCertificate.pem -idevidcert /opt/hpe/scl/certificates/IDevIDCertificate.pem -forceRootCA /opt/hpe/scl/certificates/root_cert.pem
