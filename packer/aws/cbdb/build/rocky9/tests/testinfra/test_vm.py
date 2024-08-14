import testinfra

def test_etc_hosts_file(host):
    """Check the /etc/hosts file exists and has correct ownership."""
    f = host.file("/etc/hosts")
    assert f.exists
    assert f.user == "root"
    assert f.group == "root"

def test_packages_installed(host):
    """Check that all necessary packages are installed."""
    packages = [
        "git", "vim-common", "tmux", "wget", "the_silver_searcher", "bat", "htop",
        "apr-devel", "autoconf", "bison", "bzip2", "bzip2-devel", "cmake", "ed",
        "flex", "gcc", "gcc-c++", "glibc-langpack-en", "initscripts", "iproute",
        "java-1.8.0-openjdk", "java-1.8.0-openjdk-devel", "krb5-devel", "less",
        "libcurl-devel", "libevent-devel", "libuuid-devel", "libxml2-devel",
        "libzstd-devel", "lz4", "lz4-devel", "m4", "nmap-ncat", "net-tools", "openldap-devel",
        "openssh-clients", "openssh-server", "openssl-devel", "pam-devel", "passwd",
        "perl", "perl-ExtUtils-Embed", "perl-Test-Simple", "python3-devel",
        "python3-lxml", "python3-psutil", "python3-pytest", "python3-pyyaml",
        "readline-devel", "rpm-build", "rsync", "sudo", "tar", "unzip", "util-linux", "which",
        "zlib-devel", "libuv-devel", "libyaml-devel", "perl-IPC-Run", "xerces-c-devel"
    ]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed, f"Package {package} is not installed"

def test_service_sshd(host):
    """Check that the sshd service is running and enabled."""
    sshd = host.service("sshd")
    assert sshd.is_running
    assert sshd.is_enabled

def test_port_22(host):
    """Check that port 22 (SSH) is listening."""
    port = host.socket("tcp://0.0.0.0:22")
    assert port.is_listening

def test_limits_conf(host):
    """Check the limits configuration file for gpadmin exists and has correct ownership and permissions."""
    limits_conf = host.file("/etc/security/limits.d/90-db-limits.conf")
    assert limits_conf.exists
    assert limits_conf.user == "root"
    assert limits_conf.group == "root"
    assert limits_conf.mode == 0o644

def test_sysctl_conf(host):
    """Check the sysctl configuration file exists and contains the correct settings."""
    sysctl_conf = host.file("/etc/sysctl.d/90-db-sysctl.conf")
    assert sysctl_conf.exists
    assert sysctl_conf.user == "root"
    assert sysctl_conf.group == "root"
    assert sysctl_conf.mode == 0o644

    # Check for specific sysctl settings
    sysctl_conf_content = sysctl_conf.content_string
    settings = {
        "kernel.msgmax": "65536",
        "kernel.msgmnb": "65536",
        "kernel.msgmni": "2048",
        "kernel.sem": "500 2048000 200 8192",
        "kernel.shmmni": "1024",
        "kernel.core_uses_pid": "1",
        "kernel.core_pattern": "/var/core/core.%h.%t",
        "kernel.sysrq": "1",
        "net.core.netdev_max_backlog": "2000",
        "net.core.rmem_max": "4194304",
        "net.core.wmem_max": "4194304",
        "net.core.rmem_default": "4194304",
        "net.core.wmem_default": "4194304",
        "net.ipv4.tcp_rmem": "4096 4224000 16777216",
        "net.ipv4.tcp_wmem": "4096 4224000 16777216",
        "net.core.optmem_max": "4194304",
        "net.core.somaxconn": "10000",
        "net.ipv4.ip_forward": "0",
        "net.ipv4.tcp_congestion_control": "cubic",
        "net.core.default_qdisc": "fq_codel",
        "net.ipv4.tcp_mtu_probing": "0",
        "net.ipv4.conf.all.arp_filter": "1",
        "net.ipv4.conf.default.accept_source_route": "0",
        "net.ipv4.ip_local_port_range": "10000 65535",
        "net.ipv4.tcp_max_syn_backlog": "4096",
        "net.ipv4.tcp_syncookies": "1",
        "net.ipv4.ipfrag_high_thresh": "41943040",
        "net.ipv4.ipfrag_low_thresh": "31457280",
        "net.ipv4.ipfrag_time": "60",
        "net.ipv4.ip_local_reserved_ports": "65330",
        "vm.overcommit_memory": "2",
        "vm.overcommit_ratio": "95",
        "vm.swappiness": "10",
        "vm.dirty_expire_centisecs": "500",
        "vm.dirty_writeback_centisecs": "100",
        "vm.zone_reclaim_mode": "0"
    }
    for key, value in settings.items():
        assert "{} = {}".format(key, value) in sysctl_conf_content

def test_gpadmin_limits_conf(host):
    """Check the limits configuration file for gpadmin user exists, has correct content, ownership, and permissions."""
    limits_conf = host.file("/etc/security/limits.d/90-db-limits.conf")

    # Verify the file exists
    assert limits_conf.exists, "Limits configuration file for gpadmin does not exist"

    # Verify the file content
    expected_content = """
# /etc/security/limits.d/90-db-limits.conf

# Core dump file size limits for gpadmin
gpadmin soft core unlimited
gpadmin hard core unlimited

# Open file limits for gpadmin
gpadmin soft nofile 524288
gpadmin hard nofile 524288

# Process limits for gpadmin
gpadmin soft nproc 131072
gpadmin hard nproc 131072
    """.strip()

    assert limits_conf.content_string.strip() == expected_content, "Limits configuration file content is incorrect"

    # Verify the file ownership and permissions
    assert limits_conf.user == "root", "Limits configuration file is not owned by root"
    assert limits_conf.group == "root", "Limits configuration file group is not root"
    assert limits_conf.mode == 0o644, "Limits configuration file does not have correct permissions"

def test_selinux_disabled(host):
    """Check that SELinux is permanently disabled in the configuration file."""
    selinux_config = host.file("/etc/selinux/config")
    assert selinux_config.exists, "SELinux configuration file does not exist"
    assert selinux_config.contains("SELINUX=disabled"), "SELinux is not disabled in the configuration file"

def test_gpadmin_user(host):
    """Check the gpadmin user exists with correct home directory and shell."""
    user = host.user("gpadmin")
    assert user.exists, "gpadmin user does not exist"
    assert user.home == "/home/gpadmin"
    assert user.shell == "/bin/bash"

def test_gpadmin_sudo(host):
    """Check that sudo works for gpadmin user."""
    cmd = host.run("sudo -l -U gpadmin")
    assert "NOPASSWD: ALL" in cmd.stdout, "gpadmin does not have passwordless sudo access"
