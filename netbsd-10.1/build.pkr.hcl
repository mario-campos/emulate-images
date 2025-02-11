local "root_password" {
  expression = "vagrant"
  sensitive  = true
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso
source "virtualbox-iso" "default" {

  iso_url       = "https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/images/NetBSD-10.1-amd64.iso"
  iso_checksum  = "file:https://cdn.netbsd.org/pub/NetBSD/images/10.1/SHA512"
  iso_interface = "sata"

  guest_os_type = "NetBSD_64"

  # Ubuntu-Linux GitHub-hosted runners are limited to 14 GiB SSD storage.
  # https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners#standard-github-hosted-runners-for-public-repositories
  disk_size = 14000 # 14 GB
  hard_drive_interface = "scsi"

  # Packer will use these SSH credentials to provision files and execute commands.
  # https://developer.hashicorp.com/packer/docs/communicators/ssh
  ssh_username  = "root"
  ssh_password = local.root_password

  # The method by which guest additions are made available to the guest for installation.
  # Untested on NetBSD, so disabling to be safe.
  guest_additions_mode = "disable"

  shutdown_command = "/sbin/poweroff"

  boot_wait = "30s"
  boot_command = [
    # Language selection
    "<wait5><enter><wait>",	# English

    # Keyboard type
    "<wait5><enter><wait>",	# unchanged

    # NetBSD-10.1 Install System
    "<wait5><enter><wait>",	# Install NetBSD to hard disk

    # Shall we continue?
    "b<wait><enter><wait>",	# Yes

    # Available disks
    "<wait5><enter><wait>",    # wd0

    # Partitioning scheme
    "<wait5><enter><wait>",	# GPT

    # Correct geometry?
    "<wait5><enter><wait>",	# This is the correct geometry

    # How to partition?
    "b<wait5><enter><wait>",	# Use default partition sizes

    # Review: partition sizes
    "<wait5><enter><wait>",	# Partition sizes OK

    # Shall we continue?
    "b<wait><enter><wait5>",	# Yes

    # Bootblocks selection
    "<wait5><enter><wait>",	# Use BIOS console

    # Select your distribution
    "<wait5>",
    "d<wait><enter><wait>",	# Custom installation
    "f<wait><enter><wait>",	# Compiler tools: Yes
    "x<wait><enter><wait>",

    # Install from
    "<wait5><enter><wait2m>",	# CD-ROM / DVD / install image media

    # Installation complete
    "<enter><wait>",	# Hit enter to continue

    # Enter password
    "${local.root_password}<enter><wait>", # this first one is a weak-password warning
    "${local.root_password}<enter><wait>",
    "${local.root_password}<enter><wait5>",

    # Configure the additional items as needed
    "<wait5>",
    "a<wait><enter><wait>",	# Configure network

    # Which network interface?
    "<wait5><enter><wait>",	# wm0

    # Network media type (empty to autoconfigure)
    "<wait5><enter><wait>",	# autoselect

    # Perform autoconfiguration?
    "<wait><enter><wait15>",	# Yes

    # Your host name
    "runner.local<wait><enter><wait>",

    # Your DNS domain
    "local<wait><enter><wait>",

    # Are they OK?
    "<wait><enter><wait>",	# Yes

    # Do you want it installed in /etc?
    "<wait5><enter><wait>",	# Yes

    "g<wait><enter>",		# Enable sshd
    "h<wait><enter>",		# Enable ntpd
    "i<wait><enter>",		# Run ntpdate at boot
    "l<wait><enter>",		# Disable cgd
    "n<wait><enter>",		# Disable raidframe
    "x<wait><enter>",		# Finished configuring

    # Hit enter to continue
    "<wait><enter><wait>",

    # Installation menu
    "d<wait5><enter><wait1m>",# Reboot

    # Login prompt
    "root<enter><wait>",
    "${local.root_password}<enter><wait>",

    # Modify sshd_config to enable root login via password so that Packer may SSH in for the provision step below.
    "sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config<enter><wait>",

    # Create /root/.ssh so that Packer may upload the authorized_keys file.
    "mkdir -m 0700 /root/.ssh<enter><wait>",

    # Restart SSHd
    "service sshd restart<enter>",
  ]
}

build {
  sources = ["sources.virtualbox-iso.default"]

  provisioner "file" {
    source      = "${path.root}/sshd_config"
    destination = "/etc/ssh/sshd_config"
  }

  provisioner "file" {
    source      = "${path.root}/authorized_keys"
    destination = ".ssh/authorized_keys"
  }

  provisioner "shell" {
    environment_vars = ["PKG_PATH=https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/x86_64/10.0_2024Q4/All"]
    inline = [
      "/usr/sbin/pkg_add git got clang cmake meson pkg-config autoconf automake libtool ca-certificates",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      provider_override = "virtualbox"
      vagrantfile_template = "Vagrantfile"
    }
  }
}
