#!/bin/sh

/root/zulu11jdk/bin/java -jar /root/PCVT/pcvt_build20210301_NIST.jar -checkplatcert -hwmanif /root/tmp/HPE_hardware_manifest_tampered.json -spc /root/HPE_certificates/PlatformCertificate.pem -iakcert /root/HPE_certificates/IAKCertificate.pem -idevidcert /root/HPE_certificates/IDevIDCertificate.pem

