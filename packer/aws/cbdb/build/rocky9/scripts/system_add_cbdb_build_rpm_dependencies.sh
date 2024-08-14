#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing system_add_cbdb_build_rpm_dependencies.sh..."

# Update the package cache
sudo dnf makecache

# Install EPEL repository and import GPG keys for EPEL and Rocky Linux
sudo dnf install -y epel-release
sudo rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
sudo rpm --import https://dl.rockylinux.org/pub/sig/9/cloud/x86_64/cloud-kernel/RPM-GPG-KEY-Rocky-SIG-Cloud

# Update the package cache again to include the new repository
sudo dnf makecache

# Disable EPEL and Cisco OpenH264 repositories to avoid conflicts
sudo dnf config-manager --disable epel --disable epel-cisco-openh264

# Install basic utilities
sudo dnf install -y git vim tmux wget

# Install additional tools from EPEL repository
sudo dnf install -y --enablerepo=epel the_silver_searcher bat htop

# Install development tools and dependencies
sudo dnf install -y \
     apr-devel \
     autoconf \
     bison \
     bzip2 \
     bzip2-devel \
     cmake3 \
     ed \
     flex \
     gcc \
     gcc-c++ \
     glibc-langpack-en \
     initscripts \
     iproute \
     java-1.8.0-openjdk \
     java-1.8.0-openjdk-devel \
     krb5-devel \
     less \
     libcurl-devel \
     libevent-devel \
     libuuid-devel \
     libxml2-devel \
     libzstd-devel \
     lz4 \
     lz4-devel \
     m4 \
     nc \
     net-tools \
     openldap-devel \
     openssh-clients \
     openssh-server \
     openssl-devel \
     pam-devel \
     passwd \
     perl \
     perl-ExtUtils-Embed \
     perl-Test-Simple \
     perl-core \
     python3-devel \
     python3-lxml \
     python3-psutil \
     python3-pytest \
     python3-pyyaml \
     readline-devel \
     rpm-build \
     rsync \
     sudo \
     tar \
     unzip \
     util-linux-ng \
     wget \
     which \
     zlib-devel

# Install development tools and dependencies from CRB repository
sudo dnf install -y --enablerepo=crb \
     libuv-devel \
     libyaml-devel \
     perl-IPC-Run

# Install development tools and dependencies from EPEL repository
sudo dnf install -y --enablerepo=epel \
     xerces-c-devel

# Footer indicating the script execution is complete
echo "system_add_cbdb_build_rpm_dependencies.sh execution completed."
