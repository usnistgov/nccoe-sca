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

#network --bootproto=static --device=eth0 --ip=10.151.48.230 --netmask=255.255.255.0 --gateway=10.151.48.2 --noipv6
network --bootproto=dhcp --device=link --noipv6 --hostname=hirs-provisioner-pxe

auth --useshadow  --passalgo=sha512
#rootpw --iscrypted $6$DjDtms3NRugYYVBG$YPXxAS1Ox7lL34r6Y0qV8RywwHNdN5cI53qx6L0xxwF7lanwTQ88lU1m32pF1TAqM2mySTCs/WQb4U9xid7mb1
rootpw --iscrypted $6$JmD9RUuedb1wjOpM$AU2nxPEf5E237.SuqnelpxsXUjNjknMtJXZM6pLzuIzE8JZ6dkIwhdly.2h/p8sFu0OOdzY/3FLqAB71eVHnw1 

selinux --disabled
firewall --enabled --service=dhcp --port=32400:tcp,5001:udp,5201:udp
services --enabled="dhcpd" --disabled="sshd,wpa_supplicant"

%addon com_redhat_kdump --disabled
%end

%addon org_fedora_oscap
content-type = scap-security-guide
profile = pci-dss
%end

#============================= Package Selection ==============================#

repo --name="base" --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name="updates" --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name="extra" --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/
repo --name="epel" --baseurl=http://mirror.mrjester.net/fedora/epel/7/x86_64/
# Added local repo here for HIRS Provisioner RPMs
repo --name="hirs" --baseurl=file:///root/localrepo


%packages --excludedocs --multilib --instLangs en_US

@core

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
#qemu-guest-agent
open-vm-tools
kernel

vim
java
openssl
paccor-1.1.4-4
HIRS_Provisioner_TPM_2_0-2.0.2-1

# Exclude Packages (Slim Image)
-abrt*
-aic94xx-firmware
-alsa-*
-audit
-authselect*
-avahi*
-a*firmware*
-biosdevname
-centos-logos
-chrony
-cracklib*
-dhclient
-dracut-config-rescue
-geolite2-*
-i*firmware*
-iwl*
-initscripts
-iprutils
-kernel-tools
-kexec-tools
-lib*firmware*
-libxkbcommon
-lshw
-openldap
-openssh*
-parted
-plymouth
-postfix
-rdma*
-*rhn*
-sg3_utils*
-*spacewalk*
-sqlite
-sssd*
-subs*
-trousers
-tuned
-wpa_supplicant

%end

#========================= Post-Installation Scripts ==========================#
#==============================================================================#

%post

#============================= Pre-Login Message ==============================#

cat <<EOF >/etc/issue
                          Computing Device Acceptance Testing 

EOF

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

%end
