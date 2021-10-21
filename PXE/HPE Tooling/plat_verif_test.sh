#!/bin/sh

rm /root/HPE\ Tooling/tmp/HpePlatformCertificateSCLdata
rm /root/HPE\ Tooling/tmp/HPE_hardware_manifest.json 
cp /sys/firmware/efi/efivars/HpePlatformCertificate-b250b9d5-40e6-b2bb-af7c-4f9e95a15b31 /root/HPE\ Tooling/tmp/HpePlatformCertificateSCLdata

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/HPE\ Tooling/PCVT/diskscan-lib ; /usr/bin/java -jar /root/HPE\ Tooling/PCVT/pcvt_build20210301_NIST.jar -genhwmanif -scl /root/HPE\ Tooling/tmp/HpePlatformCertificateSCLdata -o /root/HPE\ Tooling/tmp/HPE_hardware_manifest.json 

/usr/bin/java -jar /root/HPE\ Tooling/PCVT/pcvt_build20210301_NIST.jar -checkplatcert -hwmanif /root/HPE\ Tooling/tmp/HPE_hardware_manifest.json -spc /root/HPE\ Tooling/HPE_certificates/PlatformCertificate.pem -iakcert /root/HPE\ Tooling/HPE_certificates/IAKCertificate.pem -idevidcert /root/HPE\ Tooling/HPE_certificates/IDevIDCertificate.pem

