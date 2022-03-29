FROM amazonlinux:2

# Install packages for building HIRS
RUN yum -y update && yum clean all
RUN yum groupinstall -y "Development Tools"
RUN yum install -y wget java-1.8.0-openjdk-devel protobuf-compiler rpm-build cmake make git gcc-c++ doxygen graphviz python3 libssh2-devel openssl protobuf-devel tpm2-tss-devel tpm2-abrmd-devel trousers-devel libcurl-devel

# Install EPEL
WORKDIR /tmp
RUN wget -O epel.rpm -nv https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y ./epel.rpm
RUN yum install -y cppcheck log4cplus-devel re2-devel

# Set Environment Variables
ENV JAVA_HOME /usr/lib/jvm/java

# Install packages for installing HIRS ACA
RUN yum -y update && yum clean all
RUN yum install -y mariadb-server openssl tomcat java-1.8.0 rpmdevtools coreutils initscripts chkconfig sed grep firewalld policycoreutils && yum clean all

COPY hirsaca/HIRS_AttestationCA-2.1.2-1644956897.4e7f45.el7.noarch.rpm /root

COPY setup_aca.sh /root
RUN chmod +x /root/setup_aca.sh
# Expose ACA Port
EXPOSE 8443