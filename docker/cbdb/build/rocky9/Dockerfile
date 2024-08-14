FROM rockylinux/rockylinux:9

ARG TIMEZONE_VAR="America/Los_Angeles"

ENV container=docker
ENV LANG=en_US.UTF-8
ENV USER=gpadmin

RUN dnf update -y && \
    dnf install -y systemd \
                   systemd-libs && \
    dnf clean all

# Clean up unnecessary systemd units
RUN [ -d /lib/systemd/system/sysinit.target.wants ] && find /lib/systemd/system/sysinit.target.wants/ -type l -not -name 'systemd-tmpfiles-setup.service' -delete || echo "Directory /lib/systemd/system/sysinit.target.wants does not exist" && \
    [ -d /lib/systemd/system/multi-user.target.wants ] && find /lib/systemd/system/multi-user.target.wants/ -type l -delete || echo "Directory /lib/systemd/system/multi-user.target.wants does not exist" && \
    find /etc/systemd/system/*.wants/ -type l -delete || echo "Directory /etc/systemd/system/*.wants does not exist" && \
    [ -d /lib/systemd/system/local-fs.target.wants ] && find /lib/systemd/system/local-fs.target.wants/ -type l -delete || echo "Directory /lib/systemd/system/local-fs.target.wants does not exist" && \
    [ -d /lib/systemd/system/sockets.target.wants ] && find /lib/systemd/system/sockets.target.wants/ -type l -not -name '*udev*' -delete || echo "Directory /lib/systemd/system/sockets.target.wants does not exist" && \
    [ -d /lib/systemd/system/basic.target.wants ] && find /lib/systemd/system/basic.target.wants/ -type l -delete || echo "Directory /lib/systemd/system/basic.target.wants does not exist" && \
    [ -d /lib/systemd/system/anaconda.target.wants ] && find /lib/systemd/system/anaconda.target.wants/ -type l -delete || echo "Directory /lib/systemd/system/anaconda.target.wants does not exist"

RUN     echo root:cbdb@123 | chpasswd && \
        dnf makecache && \
        dnf install -y yum-utils \
                       epel-release \
                       git && \
        yum-config-manager --disable epel-cisco-openh264 && \
        dnf makecache && \
        yum-config-manager --disable epel && \
        dnf install -y --enablerepo=epel \
                       the_silver_searcher \
                       bat \
                       htop && \
        dnf install -y bison \
                       cmake3 \
                       ed \
                       flex \
                       gcc \
                       gcc-c++ \
                       glibc-langpack-en \
                       glibc-locale-source \
                       go \
                       initscripts \
                       iproute \
                       less \
                       m4 \
                       net-tools \
                       openssh-clients \
                       openssh-server \
                       passwd \
                       perl \
                       rsync \
                       sudo \
                       tar \
                       unzip \
                       util-linux-ng \
                       wget \
                       sshpass \
                       which && \
        dnf install -y apr-devel \
                       bzip2-devel \
                       krb5-devel \
                       libcurl-devel \
                       libevent-devel \
                       libxml2-devel \
                       libuuid-devel \
                       libzstd-devel \
                       lz4 \
                       lz4-devel \
                       openldap-devel \
                       openssl-devel \
                       pam-devel \
                       perl-ExtUtils-Embed \
                       perl-Test-Simple \
                       perl-core \
                       python3-devel \
                       readline-devel \
                       zlib-devel && \
        dnf install -y --enablerepo=crb \
                       libuv-devel \
                       libyaml-devel \
                       perl-IPC-Run && \
        dnf install -y --enablerepo=epel \
                       xerces-c-devel

COPY ./configs/* /tmp/

RUN     cp /tmp/90-cbdb-limits /etc/security/limits.d/90-cbdb-limits && \
        sed -i.bak -r 's/^(session\s+required\s+pam_limits.so)/#\1/' /etc/pam.d/* && \
        cat /usr/share/zoneinfo/${TIMEZONE_VAR} > /etc/localtime && \
        chmod 777 /tmp/init_system.sh && \
        /usr/sbin/groupadd gpadmin && \
        /usr/sbin/useradd  gpadmin -g gpadmin -G wheel && \
        setcap cap_net_raw+ep /usr/bin/ping && \
        echo "cbdb@123"|passwd --stdin gpadmin && \
        echo 'gpadmin        ALL=(ALL)       NOPASSWD: ALL' > /etc/sudoers.d/90-gpadmin && \
        echo -e '\n# Add Cloudberry entries\nif [ -f /usr/local/cbdb/greenplum_path.sh ]; then\n  source /usr/local/cbdb/greenplum_path.sh\nfi' >> /home/gpadmin/.bashrc && \
        ssh-keygen -A && \
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
        localedef -i en_US -f UTF-8 en_US.UTF-8 && \
        echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf

# Set the default user
USER gpadmin

VOLUME [ "/sys/fs/cgroup" ]
CMD ["bash","-c","/tmp/init_system.sh"]
