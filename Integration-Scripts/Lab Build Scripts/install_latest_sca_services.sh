#!/bin/bash

aca_container=hirs-aca1
hirs_hostname=`hostnamectl --static`

if [ ! -d "/root/sca-project-services" ]
then
        echo "Downloading sca-project-services"
        #clone the new repository
        git clone --recurse-submodules  -b master ssh://git@git.codev.mitre.org/hrot/sca-project-services.git
fi

echo "Updating the Git repository, building the latest Docker image, and running ..."
#build and run
(
        cd sca-project-services
        git pull
        git submodule foreach git pull origin main
        docker-compose down
        docker-compose up --build -d
)

# Deploy script adapted from HIRS ACA CI testing for NCCoE
# After deploy, load trusted and platform certificates

source sys_test_common.sh
echo "ACA Container info: $(checkContainerStatus $aca_container)";

while true
do
        echo "Checking if HIRS-ACA is up before uploading certificates..."
        curl -s -k -f -o /dev/null https://$hirs_hostname:8443/HIRS_AttestationCAPortal/portal/index
        if [ $? == 0 ] ; then
                echo "Services up!"
                break
        fi

        echo "HIRS-ACA not up yet. Retrying in 10..."
        sleep 10
done


uploadTrustedCerts "$hirs_hostname"


uploadPlatformCerts "$hirs_hostname"

echo "Setting the HIRS-ACA policy"
setPolicyEkPc "$aca_container"
