# emulate-images

This repository contains the virtual-machine images that are used for [emulate](https://github.com/mario-campos/emulate).

## How to build an image

To build one of these images into a Vagrant box, you'll need some open-source software:

* VirtualBox
* Hashicorp Vagrant
* Hashicorp Packer

You'll also need to install some `packer` plugins:

```shell
packer plugins install github.com/hashicorp/vagrant
packer plugins install github.com/hashicorp/virtualbox
```

Finally, run `packer build` with an OS subdirectory as an argument. For example:

```shell
packer build openbsd-7.3
```