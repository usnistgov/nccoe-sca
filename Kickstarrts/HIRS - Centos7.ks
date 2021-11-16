install
text
lang en_US
keyboard 'us'
timezone Etc/UTC
firstboot --disabled

zerombr
clearpart --all --initlabel
autopart --type=lvm --encrypted --passphrase=password
bootloader --location=mbr --append="net.ifnames=0 biosdevname=0"



network --bootproto=dhcp --device=link --noipv6 --hostname=hirs-provisioner-pxe

auth --useshadow  --passalgo=sha512
rootpw --iscrypted $6$JmD9RUuedb1wjOpM$AU2nxPEf5E237.SuqnelpxsXUjNjknMtJXZM6pLzuIzE8JZ6dkIwhdly.2h/p8sFu0OOdzY/3FLqAB71eVHnw1 

selinux --disabled
firewall --enabled --service=dhcp --port=32400:tcp,5001:udp,5201:udp
services --enabled="dhcpd" --disabled="wpa_supplicant"

%addon com_redhat_kdump --disabled
%end

%addon org_fedora_oscap
content-type = scap-security-guide
profile = pci-dss
%end

#============================= Package Selection ==============================#

# Using local proxy to cache RPMs

repo --name="sca" --baseurl=file:////root/centos7/sca-packages 
repo --name="base" --baseurl=http://mirror.centos.org/centos/7/os/x86_64/ --proxy=http://localhost:3128
repo --name="updates" --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/ --proxy=http://localhost:3128
repo --name="extra" --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/ --proxy=http://localhost:3128
repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/ --proxy=http://localhost:3128
repo --name=centos-sclo --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh --proxy=http://localhost:3128


%packages --excludedocs --multilib --instLangs en_US --ignoremissing 

@core

# Newer kernel
kernel-ml
kernel-ml-devel
kernel-ml-tools
kernel-ml-tools-libs
kernel-ml-headers

# System Specific Packages
dhcp

# BIOS/UEFI Cross-Compatibility Packages
efibootmgr
grub2-efi-x64
grub2-efi-x64-cdboot
grub2-efi-x64-modules
grub2-pc
grub2-pc-modules
grub2-tools*
shim-x64

# Guest Utilities (Only One)
open-vm-tools


vim
java
openssl
paccor-1.1.4-5
HIRS_Provisioner_TPM_2_0-2.0.2

log4cplus
protobuf
re2
libcurl
wget
procps
openssh-server

centos-release-scl
devtoolset-9

# Exclude Packages (Slim Image)
#-abrt*
#-aic94xx-firmware
#-alsa-*
#-audit
#-authselect*
#-avahi*
#-a*firmware*
#-biosdevnam
#-centos-logos
#-chrony
#-cracklib*
#-dhclient
#-dracut-config-rescue
#-geolite2-*
#-i*firmware*
#-iwl*
#-initscripts
#-iprutils
-kernel-tools
#-kexec-tools
#-lib*firmware*
#-libxkbcommon
#-lshw
#-openldap
#-parted
#-plymouth
#-postfix
#-rdma*
-*rhn*
#-sg3_utils*
#-*spacewalk*
#-sqlite
#-sssd*
#-subs*
#-trousers
#-tuned
#-wpa_supplicant

%end

#========================= Post-Installation Scripts ==========================#
#==============================================================================#

%post





cat <<EOF >/etc/issue
                          Computing Device Acceptance Testing 

EOF

#============================== Install Tools =================================#
cat >> /etc/hosts <<EOF
10.32.50.169 hirs-aca.sca.lab.nccoe.org
EOF

#============================= Update certs +==================================#


curl -o /etc/pki/ca-trust/source/anchors/curl-cacert.pem http://hirs-aca.sca.lab.nccoe.org/curl-cacert.pem
curl -o /etc/pki/ca-trust/source/anchors/isrg-root-x1.pem http://hirs-aca.sca.lab.nccoe.org/isrg-root-x1.pem
curl -o /etc/pki/ca-trust/source/anchors/root-ca-x3.pem http://hirs-aca.sca.lab.nccoe.org/root-ca-x3.pem

update-ca-trust

cd /root/
curl http://hirs-aca.sca.lab.nccoe.org/eclypsium_agent_builder-2.8.1.run -o /root/eclypsium_agent_builder-2.8.1.run
chmod +x /root/eclypsium_agent_builder-2.8.1.run

cat >> /etc/systemd/system/tpm2-abrmd <<EOF
[Unit]
Description=tpm2-abrmd

[Service]
ExecStart=tpm2-abrmd

[Install]
WantedBy=multi-user.target
EOF

systemctl enable tpm2-abrmd

#============================== Configure Provisioner =========================#

cat <<EOF >/etc/hirs/hirs-site.config
#*******************************************
#* HIRS site configuration properties file
#*******************************************

# Client configuration
CLIENT_HOSTNAME=hirs-provisioner-pxe
TPM_ENABLED=true
IMA_ENABLED=false

# Site-specific configuration
ATTESTATION_CA_FQDN=hirs-aca.sca.lab.nccoe.org
ATTESTATION_CA_PORT=8443
BROKER_FQDN=hirs-aca.sca.lab.nccoe.org
BROKER_PORT=61616
PORTAL_FQDN=hirs-aca.sca.lab.nccoe.org
PORTAL_PORT=8443
EOF


#================================ Create User =================================#

/usr/sbin/useradd \
    -p '$6$yOpyymJYxjNxp62J$CcNpqLoBkMIRQEksafVs3/LkV7SEFmcBWmS5kV9EquW7V33p83jGw3LDFITXYJlZWS/of7BZTp5tR8.BD.xz00' \
    -G wheel \
    -c 'IT Administrators' \
    tsmith

#======================= Disable Unnecessary Functions ========================#

cat <<EOF >>/etc/sysctl.conf
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF

cat <<EOF >>/etc/modprobe.d/my-blacklist.conf
blacklist floppy
blacklist pcspkr
blacklist snd_pcsp
EOF

#=================================== Clean ====================================#

yum -C clean all

/bin/rm -rf \
    /etc/*- \
    /etc/*.bak \
    /var/tmp/*

/bin/rm -rf \
    /var/cache/yum/* \
    /var/lib/yum/repos/* \
    /var/lib/yum/yumdb/*

/bin/rm -rf \
    /var/log/*debug \
    /var/log/anaconda \
    /var/lib/rhsm


#=================================== Download script =============================#
curl http://hirs-aca.sca.lab.nccoe.org/provision.sh -o /root/provision.sh
rpm -ihv http://hirs-aca.sca.lab.nccoe.org/hipxe-drivers-1.0-1.noarch.rpm
chmod +x /root/provision.sh

%end
