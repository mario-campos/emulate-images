# NetBSD 9.2

- User: root
- vCPU: 4
- RAM: 15 GiB
- Storage: 14 GB

### Included packages

- autoconf
- automake
- ca-certificates
- git
- got
- clang
- cmake
- libtool
- meson
- pkg-config
 
### Customizations

- Disabled [RAIDframe](https://www.netbsd.org/docs/guide/en/chap-rf.html).
- Disabled The [Cryptographic Device Driver (CGD)](https://www.netbsd.org/docs/guide/en/chap-cgd.html).
- Enabled [ntpdate(8)](https://man.netbsd.org/NetBSD-6.0/ntpdate.8).
- Enabled [ntpd(8)](https://man.netbsd.org/ntpd.8).
