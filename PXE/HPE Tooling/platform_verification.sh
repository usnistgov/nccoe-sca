#!/bin/sh

rm /root/tmp/HPE_hardware_manifest.json 

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/PCVT/diskscan-lib ; /root/zulu11jdk/bin/java -jar /root/PCVT/pcvt_build20210301_NIST.jar -genhwmanif -scl /opt/hpe/scl/HpePlatformCertificateSCLdata -o /root/tmp/HPE_hardware_manifest.json 

/root/zulu11jdk/bin/java -jar /root/PCVT/pcvt_build20210301_NIST.jar -checkplatcert -hwmanif /root/tmp/HPE_hardware_manifest.json -spc /root/HPE_certificates/PlatformCertificate.pem -iakcert /root/HPE_certificates/IAKCertificate.pem -idevidcert /root/HPE_certificates/IDevIDCertificate.pem

