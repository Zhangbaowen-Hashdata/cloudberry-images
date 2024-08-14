import testinfra

def test_go_installed(host):
    # Verify that Go executable exists and is a file
    go = host.file("/usr/local/go/bin/go")
    assert go.exists, "Go binary does not exist"
    assert go.is_file, "Go binary is not a file"
    assert go.mode == 0o755, "Incorrect permissions on Go binary"

def test_go_version(host):
    # Verify the Go version
    cmd = host.run("/usr/local/go/bin/go version")
    assert cmd.succeeded, "Failed to run 'go version' command"
    assert "go1.22.6" in cmd.stdout, f"Unexpected Go version: {cmd.stdout}"

def test_profile_d_updated(host):
    # Verify PATH update in /etc/profile.d/go.sh
    profile_d = host.file("/etc/profile.d/go.sh")
    assert profile_d.exists, "/etc/profile.d/go.sh does not exist"
    assert profile_d.is_file, "/etc/profile.d/go.sh is not a file"
    assert 'export PATH=$PATH:/usr/local/go/bin' in profile_d.content_string, \
        "/etc/profile.d/go.sh does not contain the expected PATH update"
