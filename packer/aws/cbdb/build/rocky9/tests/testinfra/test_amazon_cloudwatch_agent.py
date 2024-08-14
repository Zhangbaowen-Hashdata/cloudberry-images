import testinfra

# Define the packages to be tested
packages = [
    "wget",
    "curl",
    "jq",
    "git",
    "podman-docker",
    "amazon-cloudwatch-agent",
    "amazon-ssm-agent"
]

# Define the services to be tested
services = [
    "amazon-cloudwatch-agent",
    "amazon-ssm-agent"
]

def test_packages_installed(host):
    """
    Test if the required packages are installed.
    """
    for pkg in packages:
        package = host.package(pkg)
        assert package.is_installed

def test_services_running_and_enabled(host):
    """
    Test if the required services are running and enabled.
    """
    for srv in services:
        service = host.service(srv)
        assert service.is_running
        assert service.is_enabled

def test_cloudwatch_agent_config_exists(host):
    """
    Test if the CloudWatch Agent configuration file exists.
    """
    config_file = host.file("/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json")
    assert config_file.exists
    assert config_file.is_file
