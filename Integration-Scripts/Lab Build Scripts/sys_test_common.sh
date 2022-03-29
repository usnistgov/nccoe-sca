#!/bin/bash
#########################################################################################
#    Adapted from functions used for HIRS system tests
#    https://github.com/nsacyber/HIRS/blob/master/.ci/system-tests/sys_test_common.sh
#
#########################################################################################

# Check container status and abort if container is not running
checkContainerStatus() {
  container_name=$1
  container_id="$(docker ps -aqf "name=$container_name")"
  container_status="$(docker inspect $container_id --format='{{.State.Status}}')"
  echo "Container id is $container_id and the status is $container_status"

  if [ "$container_status" != "running" ]; then
     container_exit_code="$(docker inspect $container_id --format='{{.State.ExitCode}}')"
     echo "Container Exit Code: $container_exit_code"
     docker info
     exit 1;
fi
}

# clear all policy settings
setPolicyNone() {
docker exec $aca_container mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=0, enablePcAttributeValidation=0, enablePcValidation=0,
           enableUtcValidation=0, enableFirmwareValidation=0, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"
}

# Policy Settings for tests ...
setPolicyEkOnly() {
docker exec $aca_container mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=1, enablePcAttributeValidation=0, enablePcValidation=0,
           enableUtcValidation=0, enableFirmwareValidation=0, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"
}

setPolicyEkPc_noAttCheck() {
docker exec $aca_container mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=1, enablePcAttributeValidation=0, enablePcValidation=1,
           enableUtcValidation=0, enableFirmwareValidation=0, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"
}

setPolicyEkPc() {
#docker exec $aca_container mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=1, enablePcAttributeValidation=1, enablePcValidation=1,
#           enableUtcValidation=0, enableFirmwareValidation=0, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"
docker exec $1 mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=1, enablePcAttributeValidation=1, enablePcValidation=1,
           enableUtcValidation=0, enableFirmwareValidation=0, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"

}


setPolicyEkPcFw() {
docker exec $aca_container mysql -u root -D hirs_db -e "Update SupplyChainPolicy set enableEcValidation=1, enablePcAttributeValidation=1, enablePcValidation=1,
           enableUtcValidation=0, enableFirmwareValidation=1, enableExpiredCertificateValidation=0, enableIgnoreGpt=0, enableIgnoreIma=0, enableIgnoretBoot=0;"
}

# Clear all ACA DB items including policy
clearAcaDb() {
docker exec $aca_container mysql -u root -e "use hirs_db; set foreign_key_checks=0; truncate Alert;truncate AlertBaselineIds;truncate
 AppraisalResult;truncate Certificate;truncate Certificate_Certificate;truncate CertificatesUsedToValidate;truncate
 ComponentInfo;truncate Device;truncate DeviceInfoReport;truncate IMADeviceState;truncate IMAMeasurementRecord;truncate
 ImaBlacklistRecord;truncate ImaIgnoreSetRecord;truncate IntegrityReport;truncate IntegrityReports_Reports_Join;truncate
 RepoPackage_IMABaselineRecord;truncate Report;truncate ReportMapper;truncate ReportRequestState;truncate ReportSummary;truncate
 State;truncate SupplyChainValidation;truncate SupplyChainValidationSummary;truncate ReferenceManifest;truncate
 ReferenceDigestRecord; truncate ReferenceDigestValue; truncate
 SupplyChainValidationSummary_SupplyChainValidation;truncate TPM2ProvisionerState;truncate TPMBaselineRecords;truncate
 TPMDeviceState;truncate TPMReport;truncate TPMReport_pcrValueList; set foreign_key_checks=1;"
}

# Upload Certs to the ACA DB
uploadTrustedCerts() {

hirs_hostname=$1

TRUSTED_CERTIFICATE_DIRECTORY=trust_management_certificates

for cert in $TRUSTED_CERTIFICATE_DIRECTORY/*
do
  echo "Uploading $cert to HIRS ACA container..."
  curl -k -s -F "file=@$cert" https://$hirs_hostname:8443/HIRS_AttestationCAPortal/portal/certificate-request/trust-chain/upload
done

}


# Upload Certs to the ACA DB
uploadPlatformCerts() {


hirs_hostname=$1

PLATFORM_CERTIFICATE_DIRECTORY=platform_certificates

for cert in $PLATFORM_CERTIFICATE_DIRECTORY/*
do
  echo "Uploading $cert to HIRS ACA container..."
  curl -k  -s -F "file=@$cert" https://$hirs_hostname:8443/HIRS_AttestationCAPortal/portal/certificate-request/platform-credentials/upload
done

}

# Places platform cert(s) held in the test folder(s) in the provisioners tcg folder
# setPlatCert <profile> <test>
setPlatformCerts() {
  docker exec $tpm2_container sh /HIRS/.ci/system-tests/container/pc_setup.sh $1 $2  
}
