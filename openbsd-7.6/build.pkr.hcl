local "root_password" {
  expression = "vagrant"
  sensitive  = true
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso
source "virtualbox-iso" "default" {

  iso_url       = "https://cdn.openbsd.org/pub/OpenBSD/7.6/amd64/install76.iso"
  iso_checksum  = "file:https://cdn.openbsd.org/pub/OpenBSD/7.6/amd64/SHA256"
  iso_interface = "sata"

  guest_os_type = "OpenBSD_64"

  # Use 2 vCPUs to install OpenBSD, so that it will use the bsd.mp kernel.
  cpus = 2

  # The VM needs 1024 MB of RAM in order install successfully.
  memory = 1024

  # Ubuntu-Linux GitHub-hosted runners are limited to 14 GiB SSD storage.
  # https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners#standard-github-hosted-runners-for-public-repositories
  disk_size = 14000 # 14 GB
  hard_drive_interface = "scsi"

  # Packer will use these SSH credentials to provision files and execute commands.
  # https://developer.hashicorp.com/packer/docs/communicators/ssh
  ssh_username = "root"
  ssh_password = "${local.root_password}"

  # The method by which guest additions are made available to the guest for installation.
  # OpenBSD neither needs guest additions for installation nor supports it.
  guest_additions_mode = "disable" # OpenBSD is unsupported

  shutdown_command = "shutdown -p now"

  boot_wait = "1m"
  boot_command = [
    # (I)nstall, (U)pgrade, (Autoinstall, or (S)hell?
    "I<enter><wait5>", # Install

    # Choose your keyboard layout [default]
    "<enter><wait5>",

    # System hostname?
    "runner<enter><wait5>",

    # Network interface to configure? [em0]
    "<enter><wait5>",

    # IPv4 address for vio0?
    "<enter><wait10>", # default (autoconf, none)

    # IPv6 address for vio0?
    "<enter><wait10>", # default (autoconf, none)

    # Network interface to configure? [done]
    "<enter><wait5>",

    # Password for root account?
    "${local.root_password}<enter><wait5>",

    # Password for root account? (again)
    "${local.root_password}<enter><wait5>",

    # Start sshd(8) by default? [yes]
    "<enter><wait5>",

    # Do you expect to run the X window system?
    "no<enter><wait5>",

    # Setup a user? [no]
    "<enter><wait5>",

    # Allow root ssh login?
    "yes<enter><wait5>",

    # What timezone are you in? [UTC]
    "<enter><wait5>",

    # Which disk is the root disk? [sd0]
    "<enter><wait5>",

    # Encrypt the root disk with a passphrase or keydisk?
    "no<enter><wait5>",

    # Use (W)hole disk MBR, whole disk (G)PT or (E)dit? [whole]
    "<enter><wait5>",

    # (A)uto layout, (E)dit auto layout, or create (C)ustom layout?
    "c<enter><wait5>",

    # Add partition 'a'
    "a a<enter><wait5>",

    # offset: [64]
    "<enter><wait5>",

    # size: [33554368]
    "<enter><wait5>",

    # FS type: [4.2BSD]
    "<enter><wait5>",

    # mount point:
    "/<enter><wait5>",

    # quit & save changes
    "q<enter><wait5>", 

    # Write new label?
    "y<enter><wait5>",

    # Location of sets? [cd0] 
    "<enter><wait5>",

    # Pathname to the sets? [7.6/amd64]
    "<enter><wait5>",

    # Set name(s)?
    "-game* -man*<enter><wait5>", # exclude games and manual pages

    # Set name(s)? [done]
    "<enter><wait5>",

    # Directory does not contain SHA256.sig. Continue without verification?
    "yes<enter><wait3m>",

    # Location of sets? (cd0 disk http nfs or 'done') [done]
    "<enter><wait5>",

    # Time appears wrong. Set to '...'? [yes]
    "<enter><wait3m>",

    # Exit to (S)hell, (H)alt or (R)eboot? [reboot]
    "<enter>",
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
    destination = "/root/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "pkg_add git got cmake meson autoconf-2.72p0 automake-1.16.5 libtool",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      provider_override = "virtualbox"
      vagrantfile_template = "Vagrantfile"
    }
  }
}
