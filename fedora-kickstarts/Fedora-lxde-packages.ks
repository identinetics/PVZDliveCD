%packages
@base-x
#@guest-desktop-agents
#@standard
@core
#@fonts
#@input-methods
@dial-up
#@multimedia
@hardware-support
#@printing
coreutils-single

# Explicitly specified here:
# <notting> walters: because otherwise dependency loops cause yum issues.
kernel
kernel-modules
kernel-modules-extra

anaconda
#@anaconda-tools
#-system-config-keyboard    # disappeared from repe on 2017-02-02

# Need aajohan-comfortaa-fonts for the SVG rnotes images
aajohan-comfortaa-fonts

# Without this, initramfs generation during live image creation fails: #1242586
dracut-live
grub2-efi
syslinux
efibootmgr
shim

# anaconda needs the locales available to run for different locales
glibc-all-langpacks

# save some space
-mpage
-sox
-hplip
-numactl
-isdn4k-utils
-autofs

# opensc seems to have broader card support than coolkey
-coolkey
pcsc-lite
pcsc-tools
usbutils
opensc

# scanning takes quite a bit of space :/
-xsane
-xsane-gimp
-sane-backends

### LXDE desktop
@lxde-desktop
#@lxde-apps
#@lxde-media
#@lxde-office
@networkmanager-submodules

midori
# system-config-network  # disappeared from repe on 2017-02-02
xfce4-terminal

#Docker
docker-engine
nload
wget


# rebranding
-fedora-logos
-fedora-release
-fedora-release-notes
generic-release
generic-logos
generic-release-notes

# pam-fprint causes a segfault in LXDM when enabled
-fprintd-pam


# LXDE has lxpolkit. Make sure no other authentication agents end up in the spin.
-polkit-gnome
-polkit-kde

# make sure xfce4-notifyd is not pulled in
notification-daemon
-xfce4-notifyd

# make sure xfwm4 is not pulled in for firstboot
# https://bugzilla.redhat.com/show_bug.cgi?id=643416
metacity


# dictionaries are big
-man-pages-*
-words

# save some space
-autofs
-acpid
-gimp-help
-desktop-backgrounds-basic
-realmd                     # only seems to be used in GNOME
-PackageKit*                # we switched to yumex, so we don't need this
-foomatic-db-ppds
-foomatic
-stix-fonts
-ibus-typing-booster
-xscreensaver-extras
-wqy-zenhei-fonts           # FIXME: Workaround to save space, do this in comps

# drop some system-config things
-system-config-language
-system-config-rootpassword
-system-config-services
-policycoreutils-gui
-gnome-disk-utility
-firewalld
-firewall*
-libselinux*
-selinux*
-sylpheed
-wayland*
-*wayland
-btrfs*
-ntfs*
-tigervnc*

# Fonts
liberation-mono-fonts

# exFAT Support
fuse-exfat

# CUPS printing with a larger selection of drivers, converters and Libreoffice as print helper
cups
system-config-printer
gutenprint-cups
hplip
ImageMagick
libreoffice

# Python 3 (Status scripts)
python3

# JRE and icedtea-web (= Java Webstart)
icedtea-web


%end
