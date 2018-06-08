# https://www.youtube.com/watch?v=Su46AjtyTqw
# https://blog.tincho.org/posts/Setting_up_my_server:_re-installing_on_an_encripted_LVM/
# https://github.com/jocutajar/nuxnap
# http://www.itzgeek.com/how-tos/mini-howtos/change-default-network-name-ens33-to-old-eth0-on-ubuntu-16-04.html

Password : ***

################################
### on rescue ubuntu
################################

sudo -i

# parted /dev/sda
# mklabel gpt
# quit

cfdisk

### delete all partitions

shutdown -r now

sudo -i
cfdisk

###
300 MB 		bootable
1 TB		other
###

shutdown -r now

sudo -i
cfdisk
apt-get update && apt-get install btrfs-tools cryptsetup-bin debootstrap 
# apt-get update && apt-get install btrfs-tools cryptsetup cryptsetup-bin debootstrap lvm2 debian-archive-keyring

# mkfs.btrfs /dev/sda1
mkfs.ext4 /dev/sda1
cryptsetup -s 512 -c aes-xts-plain64 luksFormat /dev/sda2
################################
# cryptpass
################################
cryptsetup luksDump /dev/sda2 | grep UUID
################################
UUID:          	9704c7c9-***
################################
cryptsetup luksOpen /dev/sda2 sda2_crypt

pvcreate /dev/mapper/sda2_crypt
vgcreate vg0 /dev/mapper/sda2_crypt
vgdisplay
################################
# swap 4g | "/" 35g | /var/www 430g |
| "/" 927g | swap 4g |
################################
# lvcreate -L 31g -n system vg0
lvcreate -L 927g -n debian vg0
lvcreate -L 4g -n swap vg0

# mkfs.ext4 -L data /dev/mapper/vg0-debian
mkfs.btrfs -L data /dev/mapper/vg0-debian
mkswap -L swap /dev/mapper/vg0-swap
# mkfs.ext4 -L system /dev/mapper/vg0-system

cd /
mkdir target
mount /dev/mapper/vg0-debian /target
mkdir /target/boot
mount /dev/sda1 /target/boot
swapon /dev/mapper/vg0-swap
# mkdir /target/var
# mkdir /target/var/www
# mount /dev/mapper/vg0-data /target/var/www

debootstrap --arch amd64 jessie /target http://httpredir.debian.org/debian

chmod 1777 /target/tmp

mount -o bind /dev /target/dev
mount -t proc proc /target/proc
mount -t devpts devpts /target/dev/pts
mount -t sysfs sys /target/sys

XTERM=xterm256-color LANG=en_US.UTF-8 chroot /target /bin/bash
# XTERM=xterm256-color LANG=C.UTF-8 chroot /target /bin/bash
# XTERM=xterm256-color LANG=en_US.UTF-8 chroot /target /usr/bin/zsh

################################
### on chroot
################################

nano /etc/apt/sources.list

################################
# deb http://mirrors.online.net/debian wheezy main
deb http://httpredir.debian.org/debian jessie main contrib non-free
deb-src http://httpredir.debian.org/debian jessie main contrib non-free

deb http://httpredir.debian.org/debian jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free

deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free

# stretch-backports
# deb http://httpredir.debian.org/debian stretch-backports main contrib non-free

# nginx mainline
# deb http://nginx.org/packages/mainline/debian/ stretch nginx
# deb-src http://nginx.org/packages/mainline/debian/ stretch nginx

# tor + experimental
# deb http://deb.torproject.org/torproject.org stretch main
# deb-src http://deb.torproject.org/torproject.org stretch main
## deb http://deb.torproject.org/torproject.org tor-experimental-0.2.7.x-stretch main
## deb-src http://deb.torproject.org/torproject.org tor-experimental-0.2.7.x-stretch main

################################

echo 'APT::Istall-Recommends "False";' > /etc/apt/apt.conf.d/02recommends

cd /tmp
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key

gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# apt-get -t jessie-backports install linux-image-amd64
apt-get update  apt-get install firmware-bnx2 busybox btrfs-tools dropbear console-setup cryptsetup grub-pc initramfs-tools kbd linux-image-amd64 locales lvm2 makedev ssh sudo

locale-gen en_US en_US.UTF-8 ru_RU.UTF-8
dpkg-reconfigure locales

passwd
adduser i
adduser i sudo
adduser i adm

nano /etc/fstab

################################
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#

# <file system>            <mount point>    <type>    <options>            <dump>    <pass>
/dev/mapper/vg0-debian     /                 btrfs      errors=remount-ro      0         1
/dev/sda1                  /boot             ext4       defaults		        0         2
/dev/mapper/vg0-swap       none              swap       sw                     0         0q

# /dev/mapper/vg0-swap        none             swap      sw                     0         0
# /dev/sda1                  /boot             ext4      rw,nosuid,nodev        0         2
# /dev/mapper/vg0-system     /                 ext4      errors=remount-ro      0         1
# /dev/mapper/vg0-data       /var/www          ext4      default                0         1
# /dev/sda1                  /boot             ext4       rw,nosuid,nodev        0         2

################################

nano /etc/hostname

################################
a-u.me
################################

hostname a-u.me
nano /etc/hosts

################################
# 127.0.0.1		localhost.localdomain localhost
127.0.0.1		$HOSTNAME.$DOMAIN $HOSTNAME
::1				localhost ip6-localhost ip6-loopback
fe00::0			ip6-localnet
# ff00::0			ip6-mcastprefix
ff02::1			ip6-allnodes
ff02::2			ip6-allrouters

################################

dpkg-reconfigure tzdata
nano /etc/crypttab

################################
# <target name>   <source device>                              <key file>  <options>
sda2_crypt         UUID=9704c7c9-***    none        luks
################################

ln -sf /proc/mounts /etc/mtab

# nano /etc/initramfs-tools/root/.ssh/authorized_keys
nano /etc/dropbear-initramfs/authorized_keys

################################
ssh-rsa AAAAB3***

################################

nano /etc/initramfs-tools/conf.d/network.config

################################
export IP=dhcp
################################

nano /etc/network/interfaces

################################
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp

################################

# nano /etc/resolv.conf

################################
# nameserver 208.67.220.220
# nameserver 208.67.220.222
# nameserver 208.67.222.220
# nameserver 208.67.222.222

# 2620:0:ccc::2
# 2620:0:ccd::2
################################

# ln -s /bin/fsck.btrfs /sbin/
update-initramfs -u -k all

exit

################################
### on rescue ubuntu
################################

umount /target/{boot,dev/pts,dev,proc,sys}
# umount -l /target/var/www
umount -l /target
swapoff -a
lvchange -an /dev/mapper/vg0-*
cryptsetup luksClose sda2_crypt

shutdown -r now

################################
### REBOOT FROM CONSOLE IN NORMAL MODE!
### on client
################################

ssh -v root@SRVIPADDR -p 22

################################
### on debian
################################

echo -ne "cryptopass" > /lib/cryptsetup/passfifo
exit

################################
### on debian
################################

su root




# /etc/cryptsetup-initramfs/conf-hook
# cryptsetup=y
