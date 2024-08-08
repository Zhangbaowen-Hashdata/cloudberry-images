# Packer variables
variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "private_key_file" {
  type    = string
  default = ""
}

variable "vm_type" {
  type    = string
  default = ""
}

variable "os_name" {
  type    = string
  default = ""
}

# Define the Amazon EBS source for building the AMI
source "amazon-ebs" "rocky9" {
  # AWS credentials
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
  region        = var.region

  # Instance type and spot price for cost efficiency
  instance_type = "t3.medium"
  spot_price    = "0.0183"

  # Define the source AMI filter to find the latest Rocky 9 base AMI
  source_ami_filter {
    filters = {
      name                = "Rocky-9-EC2-Base*x86_64"
      virtualization-type = "hvm"
    }
    owners      = ["792107900819"]
    most_recent = true
  }

  # SSH configuration
  ssh_username         = "rocky"
  ssh_keypair_name     = var.key_name
  ssh_private_key_file = var.private_key_file

  # Name of the resulting AMI with current timestamp
  ami_name = format("packer-%s-%s-%s", var.vm_type, var.os_name, formatdate("YYYYMMDD-HHmmss", timestamp()))

  # Define block device mappings
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 12  # 12 GB volume size to meet snapshot requirements
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

# Build block to define the build steps
build {
  sources = ["source.amazon-ebs.rocky9"]

  # Provisioner to add CBDB build RPM dependencies
  provisioner "shell" {
    script = "scripts/system_add_cbdb_build_rpm_dependencies.sh"
  }

  # Provisioner to add kernel configurations
  provisioner "shell" {
    script = "scripts/system_add_kernel_configs.sh"
  }

  # Provisioner to disable SELinux
  provisioner "shell" {
    script = "scripts/system_disable_SELinux.sh"
  }

  # Provisioner to add the gpadmin user
  provisioner "shell" {
    script = "scripts/system_adduser_gpadmin.sh"
  }

  # Provisioner to set ulimits for gpadmin
  provisioner "shell" {
    script = "scripts/system_add_gpadmin_ulimits.sh"
  }

  # Provisioner to configure the gpadmin environment
  provisioner "shell" {
    script = "scripts/gpadmin-configure-environment.sh"
  }

  # Provisioner to add the Amazon CloudWatch Agent
  provisioner "shell" {
    script = "scripts/system_add_action_runner.sh"
  }

  # Provisioner to add the Golang
  provisioner "shell" {
    script = "scripts/system_add_golang.sh"
  }

  # Post-processor to generate a manifest file
  post-processors {
    post-processor "manifest" {
      output = "packer-manifest.json"
    }
  }
}
