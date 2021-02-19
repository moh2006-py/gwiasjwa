# Arch Installation

A disclaimer - I am a strong advocate for the `vim` and `nvim` text editors, and as such, I use vim to edit files during installation. If you prefer emacs or nano, I encourage you to use such tools.

## Table of Contents
1. [Setup](#setup)
2. [Preliminary Internet](#preliminternet)
3. [System Time](#systime)
4. [Disk Partitioning](#diskpartition)
5. [Distro Installation](#distroinstall)
6. [Mounting with Fstab](#fstabmount)
7. [System Network Manager](networkmanager)
8. [Grub Bootloader](#grubboot)
9. [Password](#password)
10. [Locales and System Information](#locales)
11. [Installation Wrapup](#installwrap)

## Setup <a name="setup"></a>

1. For this guide, you will need the following tools:
    - A machine that can be wiped to install Archlinux
    - An ethernet connection
    - A usb drive that can be wiped (and reformatted)
2. Download [Arch](https://www.archlinux.org/download/). I downloaded version `archlinux-2020.04.01-x86_64.iso`.
3. Burn the cd image onto a usb. This can be done using a number of different tools:
    - [Balena Etcher](https://www.balena.io/etcher/)
    - [Rufus](https://rufus.ie/)
    - [Mkusb](https://help.ubuntu.com/community/mkusb)
    - Or, if you prefer command line like me:
      ```
      sudo dd bs=4M if=/path/to/iso of=/dev/sdx status=progress
      ```
      where `/dev/sdx` is the root partition of the usb (do not include specific partition numbers). You may want to run `sudo fdisk -l` first to double check the partition name.
4. Boot the machine from the live usb (you may need to modify BIOS settings to boot from a usb hard drive).

Booting into Arch will bring up a simple command prompt.

## Preliminary Internet <a name="preliminternet"></a>

1. After verifying the ethernet cable is plugged in, test the internet with `ping archlinux.org`. If internet has not yet been set up on the computer, it will likely provide the following error:
    ```
    ping: archlinux.org: Temporary failure in name resolution
    ```
    (if a response appears, `ctrl-c` to stop the ping and skip ahead to the next section.)
2. Get the names of all network cards with `ip link`. Remember the names of the cards that display. On most machines there are three:
    - `lo` represents a loopback device, which is kind of like a virtual network (this is how we access 127.0.0.1 and other localhost ports).
    - `eth0` represents an ethernet adapter. Usually the interface is given a more specific name, such as `enp0s25`. In this guide I will use `eth0` to represent the ethernet card.
    - If your machine has a wifi card, it will be represented by `wlan0`. Like the ethernet card, this is usually passes under a more specific name, like `wlp1s0`. In this guide I will use `wlan0` to represent the wireless card.
3. This installation will use ethernet to download all packages and setup future internet with ethernet and/or wifi. It is definitely possible to install Archlinux on a computer using the `wifi-menu` command, but I recommend against it because it involves a lot more complication and will be subsequently slower during install. To set up a temporary internet:
    i. Copy the netctl example ethernet configuration.
        ```
        cp /etc/netctl/examples/ethernet-static /etc/netctl
        ```
    ii. `vim /etc/netctl/ethernet-static` to change the interface to the interface found earlier.
        ```
        Interface=eth0
        ```
    iii. Enable the configuration and reboot.
        ```
        netctl enable ethernet-static
        systemctl stop dhcpcd
        systemctl disable dhcpcd
        sudo reboot
        ```
    iv. Verify `ping archlinux.org` produces a response. Do not proceed and repeat this section until a response appears.

## System Time <a name="systime"></a>

1. Update the system time.
    ```
    timedatectl set-ntp true
    ```

## Disk Partitioning <a name="diskpartition"></a>
We will be creating a main partition for all files and a swap partition for suspending and hibernation. To view the amount of memory installed in the system, run the `free` command, or the more human-readable `free -g` command. To be safe, we will make the swap partition to be twice the amount of RAM.

1. To view the disks to partition, use `fdisk -l` to display all drives and note the drive you wish to install Arch on. Make sure this drive is not the usb drive. Mine is `/dev/sda`, and as such, I will be using this drive for the purposes of this guide. Run the following command to open the partitioning editor for that disk:
    ```
    fdisk /dev/sda
    ```
2. Delete all partitions on this drive by typing `d` and `ENTER` consecutively until it states that no partitions are defined.
3. Type `p` to display the disk size.
3. Type `n` to create a new partition, and `p` to make this a primary partition. Partition number and first sector can both be left at default. You can press `ENTER` to use the default for both of these prompts.
4. This partition will be the swap partition, which will be twice the size of RAM. My system uses 16Gb of RAM, so the partition created will be 2 x 16Gb = 32Gb.
    ```
    +32G
    ```
    Press `ENTER` again to allocate for the partition, and `y` to remove the `ext4` signature.
5. The rest of the space will be used for the main partition. Using the same commands, create a partition which uses the rest of the disk. When prompted for the last sector, type `ENTER` to use the rest of the space.
6. Type `w` to write the changes to the hard drive. You will be able to use `fdisk -l` to view the changes to the disk.
7. Overwrite any existing data and change the partition extensions. In my case, my swap partition is `/dev/sda1` and my root partition is `/dev/sda2`.
    ```
    mkfs.ext4 /dev/sda2
    mkswap /dev/sda1
    swapon /dev/sda1
    ```
8. Mount the created root partition.
    ```
    mount /dev/sda2 /mnt
    ```

## Distro Installation <a name="distroinstall"></a>

1. Install the linux kernel and base. This will take some time to complete. It is also recommended to install `base-devel` development tools and an editor like `vim`.
    ```
    pacstrap /mnt base base-devel linux linux-firmware vim
    ```

## Mounting with Fstab <a name="fstabmount"></a>

`fstab` is used to mount drives to the system.

1. Generate an `fstab` file.
    ```
    genfstab -U /mnt >> /mnt/etc/fstab
    ```
2. Then log into the system.
    ```
    arch-chroot /mnt
    ```

## System Network Manager <a name="networkmanager"></a>

1. Install `networkmanager`.
    ```
    pacman -S networkmanager
    ```
2. Enable `networkmanager` on boot.
    ```
    systemctl enable NetworkManager
    ```

## Grub Bootloader <a name="grubboot"></a>

1. Install `grub`.
    ```
    pacman -S grub
    grub-install --target=i386-pc /dev/sda
    ```
2. Generate the `grub` configuration.
    ```
    grub-mkconfig -o /boot/grub/grub.cfg
    ```

## Password <a name="password"></a>

1. Set a password.
    ```
    passwd
    ```

## Locales and System Information <a name="locales"></a>

1. `vim /etc/locale.gen` to enable locales.
    ```
    en_US.UTF-8 UTF-8
    en_US ISO-8859-1
    ```
2. Then generate locales.
    ```
    locale-gen
    ```
3. `vim /etc/locale.conf` to set the system language.
    ```
    LANG=en_US.UTF-8
    ```
4. Synchronize the local time and hardware clock, where [region] is your region and [city] is your city:
    ``` 
    ln -sf /usr/share/zoneinfo/[region]/[city] /etc/localtime
    hwclock --systohc
    ```
5. `vim /etc/hostname` to name the machine. I named mine `mc`.
    ```
    mc
    ```
6. Then update `/etc/hosts` accordingly:
    ```
    127.0.0.1 localhost
    ::1 localhost
    127.0.1.1 mc.localdomain mc 
    ```

## Installation Wrapup <a name="installwrap"></a>

1. Install a system upgrade. It's good to do this on a clean install. Additionally, install useful package helper packages like `git`.
    ```
    pacman -Syyuu
    pacman -S git
    ```
2. Remove the boot entry menu with `sudo vim /etc/default/grub`:
    ```
    GRUB_TIMEOUT=0
    ```
    Update the grub, then reboot.
    ```
    grub-mkconfig -o /boot/grub/grub.cfg
    reboot
    ```
3. Exit, unmount the filesystem, and shutdown. Safely remove the usb after the machine is powered off.
    ```
    exit
    umount -R /mnt
    shutdown -h now
    ```
4. Unplug the usb and power on the machine. It should boot immediately into the Arch login. You should be able to log in using `root` as the username and the password set earlier. If not, repeat the previous steps to install Arch. Once Arch is installed, follow [cloning](../README.md#cloning) instructions to setup the server.

