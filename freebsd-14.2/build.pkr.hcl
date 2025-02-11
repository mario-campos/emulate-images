local "root_password" {
  expression = "vagrant"
  sensitive  = true
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso
source "virtualbox-iso" "default" {

  iso_url       = "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.2/FreeBSD-14.2-RELEASE-amd64-disc1.iso"
  iso_checksum  = "file:https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.2/CHECKSUM.SHA256-FreeBSD-14.2-RELEASE-amd64"
  iso_interface = "sata"

  guest_os_type = "FreeBSD_64"

  # Ubuntu-Linux GitHub-hosted runners are limited to 14 GiB SSD storage.
  # https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners#standard-github-hosted-runners-for-public-repositories
  disk_size = 14000 # 14 GB
  hard_drive_interface = "virtio"

  nic_type = "virtio"

  # Packer will use these SSH credentials to provision files and execute commands.
  # https://developer.hashicorp.com/packer/docs/communicators/ssh
  ssh_username = "root"
  ssh_password = local.root_password

  # The method by which guest additions are made available to the guest for installation.
  # Untested on FreeBSD, so disabling to be safe.
  guest_additions_mode = "disable"

  shutdown_command = "poweroff"

  boot_command = [
    # Menu prompt
    "<wait>B<wait10>",

    # Welcome
    "<wait>I<wait>", # Install

    # Keymap selection
    "<wait><enter><wait>", # continue with default keymap

    # Please choose a hostname for this machine.
    "runner<wait5><enter><wait>",

    # Distribution Select
    "k<spacebar>", # deselect kernel-dbg
    "<wait5><enter><wait>",

    # Partitioning
    "<down><wait><enter><wait>", # Auto (UFS)

    # Partition
    "<wait5>E<wait>", # Entire Disk

    # Confirmation
    "<wait5>Y<wait>",

    # Select a partition scheme for this volume
    "<wait5><enter><wait>", # MBR

    # Please review the disk setup. When complete, press the Finish button.
    "F<wait>", # Finish

    # Confirmation
    "C<wait30s>", # Commit

    # Root Password
    "${local.root_password}<enter><wait>",
    "${local.root_password}<enter><wait5>",

    # Network Configuration
    "<wait><enter><wait5>",

    # Configure IPv4
    "<wait>Y<wait>", # Yes

    # Configure DHCP
    "<wait5>Y<wait10>", # Yes

    # Configure IPv6
    "<wait5>Y<wait>", # Yes

    # Configure SLAAC
    "<wait5>Y<wait10>", # Yes

    # DNS Configuration
    "<wait5><enter><wait>",

    # Select a region
    "<wait><enter><wait>", # UTC

    # Does the timezone abbreviation 'UTC' look reasonable? 
    "<wait5>Y<wait>", # Yes

    # Time & Date - Date
    "<wait><enter><wait>", # Skip

    # Time & Date - Time
    "<wait><enter><wait>", # Skip

    # Choose the services you would like to be started at boot
    "n<spacebar>", # enable ntpd
    "d<spacebar>", # disable dumpdev
    "<wait5><enter><wait>",

    # Choose system security hardening options:
    "<wait5><enter><wait5>",

    # Add User Accounts
    "<wait5>N<wait>", # No

    # Final Configuration
    "<wait5><enter><wait>", # Exit

    # Manual Configuration
    "<wait5>Y<wait>", # Yes

    # Permit root to SSH in.
    "sed -i -e 's/^#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config<wait><enter>",

    # Disable autoboot delay and prevent user from interrupting it.
    "echo 'autoboot_delay=\"-1\"' >> /boot/loader.conf<wait><enter>",

    # Create ~/.ssh, because Packer will not create parent directories with the 'file' provisioner.
    "mkdir -m 0700 /root/.ssh<wait><enter>",

    # Return to installation prompt.
    "exit<wait><enter>",

    # Complete
    "<wait5>R" # Reboot
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
    environment_vars = ["ASSUME_ALWAYS_YES=yes"]
    inline = [
      "pkg update -f",
      "pkg install autoconf automake cmake git got libtool meson pkgconf",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      provider_override = "virtualbox"
      vagrantfile_template = "Vagrantfile"
    }
  }
}
