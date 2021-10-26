#repo --name="sca-repo" --baseurl="file:///root/centos8/sca-repo"
#repo --name="BaseOS" --baseurl="http://mirror.centos.org/centos/8/BaseOS/x86_64/os/"
#repo --name="AppStream" --baseurl="http://mirror.centos.org/centos/8/AppStream/x86_64/os/"
repo --name="epelr" --baseurl="http://mirror.rackspace.com/elrepo/elrepo/el8/x86_64/"
repo --name="BaseOS" --baseurl="http://mirror.rackspace.com/centos/8/BaseOS/x86_64/os/"
#repo --name="BaseOS" --baseurl="http://mirrors.mitre.org/centos/8/BaseOS/x86_64/os/"
repo --name="AppStream" --baseurl="http://mirror.rackspace.com/centos/8/AppStream/x86_64/os/"
#repo --name="AppStream" --baseurl="http://mirrors.mitre.org/centos/8/AppStream/x86_64/os/"

#authselect minimal
skipx
selinux --disabled

#rootpw --iscrypted $6$JmD9RUuedb1wjOpM$AU2nxPEf5E237.SuqnelpxsXUjNjknMtJXZM6pLzuIzE8JZ6dkIwhdly.2h/p8sFu0OOdzY/3FLqAB71eVHnw1
rootpw --iscrypted $6$SALT$LzA4I7R7EERO5XfvDLGBuCovbT2dBLNOtNeeGrGg1IaZD86doZkyOxxuIh2Wu8W6IIKf.WszM0FeOgLAgZIVG1

user --name='tsmith' --password='P@ssw0rd123456!' --plaintext


%packages --ignoremissing --multilib --instLangs en_US
@core
#@security-tools
#@system-admin-tools

kernel
dracut-config-generic
dracut-fips
dracut-fips-aesni
dracut-live
fipscheck
wget
vim
curl
net-tools
nano
grub2
grub2-efi-x64
grub2-efi-x64-cdboot
grub2-efi-x64-modules
grub2-pc
grub2-pc-modules
grub2-tools*
efibootmgr
shim-x64
open-vm-tools
#zulu-11
zsh
unzip

# unnecessary firmware
#-alsa*firmware*
#-iwl*firmware
#-ivtv*
#-plymouth
#-aic94xx-firmware
#-atmel-firmware
#-b43-openfwwf
#-bfa-firmware
#-ipw*-firmware
#-libertas-usb8388-firmware
#-ql*-firmware
#-rt61pci-firmware
#-rt73usb-firmware
#-xorg-x11-drv-ati-firmware
#-zd1211-firmware
%end

%post

# Per the docs resolve.conf doesn't exist yet in %post so we can't download externally

echo "Installing Java runtime..."
wget http://localhost/zulu11.52.13-ca-jdk11.0.13-linux.x86_64.rpm
yum localinstall zulu11.52.13-ca-jdk11.0.13-linux.x86_64.rpm

echo "Installing HPE acceptance test software..."
wget http://localhost/hpe-tooling.zip
unzip -d /root hpe-tooling
%end
