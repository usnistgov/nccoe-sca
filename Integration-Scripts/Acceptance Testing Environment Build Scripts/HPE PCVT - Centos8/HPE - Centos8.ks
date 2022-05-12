repo --name="epelr" --baseurl="http://mirror.rackspace.com/elrepo/elrepo/el8/x86_64/" --proxy=http://localhost:3128
repo --name="BaseOS" --baseurl="http://mirror.rackspace.com/centos/8/BaseOS/x86_64/os/" --proxy=http://localhost:3128
repo --name="AppStream" --baseurl="http://mirror.rackspace.com/centos/8/AppStream/x86_64/os/" --proxy=http://localhost:3128

#authselect minimal
skipx
selinux --disabled

# Set the root password below https://docs.fedoraproject.org/en-US/Fedora/html/Installation_Guide/sect-kickstart-commands-rootpw.html
rootpw --iscrypted <encrypted password>


# Fill in password below if desired.
user --name='tsmith' --password='' --plaintext


%packages --ignoremissing --multilib --instLangs en_US
@core


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
jq

%end

%post

# Per the docs resolve.conf doesn't exist yet in %post so we can't download externally
# In this case, setup a web server locally with the appropriate artifacts

echo "Installing Java runtime..."
rpm -ihv http://localhost/zulu11.52.13-ca-jdk11.0.13-linux.x86_64.rpm

# These are built from the PCVT GitHub repository
# https://github.com/HewlettPackard/PCVT
# Include HPE certificates if iLO is not available

echo "Installing HPE acceptance test software..."
wget http://localhost/hpe-tooling.zip
unzip -d /root hpe-tooling

echo "Installing ilorest..."
rpm -ihv http://localhost/ilorest-3.3.0-78.x86_64.rpm

echo "Installing the HPE certificates on the local filesystem..."
mkdir -p /opt/hpe/scl/certificates
cp /root/HPE\ Tooling/HPE_certificates/* /opt/hpe/scl/certificates/
cp /root/HPE\ Tooling/HPE_CA_certificates/* /opt/hpe/scl/certificates/
 
echo "Installing HPE Diskscan library..."
touch /etc/ld.so.conf.d/usrlocal.conf
cat <<EOF >/etc/ld.so.conf.d/usrlocal.conf
/usr/local/lib64  

EOF

cp /root/HPE\ Tooling/libdiskscan.so /usr/local/lib64/

echo "Copying the PCVT tool and scripts to $HOME..."
cp /root/HPE\ Tooling/pcvt-mvn-0.0.1-jar-with-dependencies.jar /root/
cp /root/HPE\ Tooling/hpe_provision.sh /root/
cp /root/HPE\ Tooling/platform_verification_CentOS8.sh /root/
chmod +x /root/hpe_provision.sh
chmod +x /root/platform_verification_CentOS8.sh

rm -rf /root/HPE\ Tooling/




%end
