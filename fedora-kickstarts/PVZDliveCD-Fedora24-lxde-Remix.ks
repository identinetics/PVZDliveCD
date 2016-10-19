# PVZD-liveCD-Fedora24-lxde-Remix.ks
#
# Description:
# - PVZD Client LiveCD with the light-weight LXDE Desktop Environment
#
# Maintainer(s):
# - Rainer Hörbe <insert mail>

lang de_AT.UTF-8
keyboard de
timezone Europe/Vienna
auth --useshadow --passalgo=sha512
selinux --disabled
firewall --disabled
xconfig --startxonboot
zerombr
clearpart --all
part / --size 5120 --fstype ext4
services --enabled=NetworkManager,ModemManager --disabled=network,sshd
network --bootproto=dhcp --device=link --activate
shutdown

repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
url --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=Docker --baseurl https://yum.dockerproject.org/repo/main/fedora/$releasever/

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
-system-config-keyboard

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

# smartcards won't really work on the livecd.
-coolkey

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
system-config-network

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

#Fonts
liberation-mono-fonts


%end

%post
#Rebranding
sed -i -e 's/Generic release/PVZD Fedora Remix/g' /etc/fedora-release /etc/issue
%end

%post
# FIXME: it'd be better to get this installed from a package
cat > /etc/rc.d/init.d/livesys << EOF
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.
### BEGIN INIT INFO
# X-Start-Before: display-manager chronyd
### END INIT INFO

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ]; then
    exit 0
fi

if [ -e /.liveimg-configured ] ; then
    configdone=1
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

livedir="LiveOS"
for arg in \`cat /proc/cmdline\` ; do
  if [ "\${arg##rd.live.dir=}" != "\${arg}" ]; then
    livedir=\${arg##rd.live.dir=}
    return
  fi
  if [ "\${arg##live_dir=}" != "\${arg}" ]; then
    livedir=\${arg##live_dir=}
    return
  fi
done

# enable swaps unless requested otherwise
swaps=\`blkid -t TYPE=swap -o device\`
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -n "\$swaps" ] ; then
  for s in \$swaps ; do
    action "Enabling swap partition \$s" swapon \$s
  done
fi
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -f /run/initramfs/live/\${livedir}/swap.img ] ; then
  action "Enabling swap file" swapon /run/initramfs/live/\${livedir}/swap.img
fi

mountPersistentHome() {
  # support label/uuid
  if [ "\${homedev##LABEL=}" != "\${homedev}" -o "\${homedev##UUID=}" != "\${homedev}" ]; then
    homedev=\`/sbin/blkid -o device -t "\$homedev"\`
  fi

  # if we're given a file rather than a blockdev, loopback it
  if [ "\${homedev##mtd}" != "\${homedev}" ]; then
    # mtd devs don't have a block device but get magic-mounted with -t jffs2
    mountopts="-t jffs2"
  elif [ ! -b "\$homedev" ]; then
    loopdev=\`losetup -f\`
    if [ "\${homedev##/run/initramfs/live}" != "\${homedev}" ]; then
      action "Remounting live store r/w" mount -o remount,rw /run/initramfs/live
    fi
    losetup \$loopdev \$homedev
    homedev=\$loopdev
  fi

  # if it's encrypted, we need to unlock it
  if [ "\$(/sbin/blkid -s TYPE -o value \$homedev 2>/dev/null)" = "crypto_LUKS" ]; then
    echo
    echo "Setting up encrypted /home device"
    plymouth ask-for-password --command="cryptsetup luksOpen \$homedev EncHome"
    homedev=/dev/mapper/EncHome
  fi

  # and finally do the mount
  mount \$mountopts \$homedev /home
  # if we have /home under what's passed for persistent home, then
  # we should make that the real /home.  useful for mtd device on olpc
  if [ -d /home/home ]; then mount --bind /home/home /home ; fi
 # [ -x /sbin/restorecon ] && /sbin/restorecon /home
  if [ -d /home/liveuser ]; then USERADDARGS="-M" ; fi
}

findPersistentHome() {
  for arg in \`cat /proc/cmdline\` ; do
    if [ "\${arg##persistenthome=}" != "\${arg}" ]; then
      homedev=\${arg##persistenthome=}
      return
    fi
  done
}

if strstr "\`cat /proc/cmdline\`" persistenthome= ; then
  findPersistentHome
elif [ -e /run/initramfs/live/\${livedir}/home.img ]; then
  homedev=/run/initramfs/live/\${livedir}/home.img
fi

# if we have a persistent /home, then we want to go ahead and mount it
if ! strstr "\`cat /proc/cmdline\`" nopersistenthome && [ -n "\$homedev" ] ; then
  action "Mounting persistent /home" mountPersistentHome
fi

if [ -n "\$configdone" ]; then
  exit 0
fi

# add fedora user with no passwd
action "Adding live user" useradd \$USERADDARGS -c "Live System User" liveuser
passwd -d liveuser > /dev/null
usermod -aG wheel liveuser > /dev/null

#create Docker group
groupadd docker
usermod -aG docker liveuser > /dev/null

# Remove root password lock
passwd -d root > /dev/null

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service 2> /dev/null || :
systemctl --no-reload disable firstboot-graphical.service 2> /dev/null || :
systemctl stop firstboot-text.service 2> /dev/null || :
systemctl stop firstboot-graphical.service 2> /dev/null || :

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || :

# turn off mdmonitor by default
systemctl --no-reload disable mdmonitor.service 2> /dev/null || :
systemctl --no-reload disable mdmonitor-takeover.service 2> /dev/null || :
systemctl stop mdmonitor.service 2> /dev/null || :
systemctl stop mdmonitor-takeover.service 2> /dev/null || :

# don't enable the gnome-settings-daemon packagekit plugin
gsettings set org.gnome.software download-updates 'false' || :

# don't start cron/at as they tend to spawn things which are
# disk intensive that are painful on a live image
systemctl --no-reload disable crond.service 2> /dev/null || :
systemctl --no-reload disable atd.service 2> /dev/null || :
systemctl stop crond.service 2> /dev/null || :
systemctl stop atd.service 2> /dev/null || :

# Docker
systemctl enable docker.service
chown root:docker /var/run/docker.socket

# Don't sync the system clock when running live (RHBZ #1018162)
sed -i 's/rtcsync//' /etc/chrony.conf

# Mark things as configured
touch /.liveimg-configured

# add static hostname to work around xauth bug
# https://bugzilla.redhat.com/show_bug.cgi?id=679486
echo "localhost" > /etc/hostname

EOF

# bah, hal starts way too late
cat > /etc/rc.d/init.d/livesys-late << EOF
#!/bin/bash
#
# live: Late init script for live image
#
# chkconfig: 345 99 01
# description: Late init script for live image.

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ] || [ -e /.liveimg-late-configured ] ; then
    exit 0
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

touch /.liveimg-late-configured

# read some variables out of /proc/cmdline
for o in \`cat /proc/cmdline\` ; do
    case \$o in
    ks=*)
        ks="--kickstart=\${o#ks=}"
        ;;
    xdriver=*)
        xdriver="\${o#xdriver=}"
        ;;
    esac
done

# if liveinst or textinst is given, start anaconda
if strstr "\`cat /proc/cmdline\`" liveinst ; then
   plymouth --quit
   /usr/sbin/liveinst \$ks
fi
if strstr "\`cat /proc/cmdline\`" textinst ; then
   plymouth --quit
   /usr/sbin/liveinst --text \$ks
fi

# configure X, allowing user to override xdriver
if [ -n "\$xdriver" ]; then
   cat > /etc/X11/xorg.conf.d/00-xdriver.conf <<FOE
Section "Device"
	Identifier	"Videocard0"
	Driver	"\$xdriver"
EndSection
FOE
fi

EOF

chmod 755 /etc/rc.d/init.d/livesys
#/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

chmod 755 /etc/rc.d/init.d/livesys-late
#/sbin/restorecon /etc/rc.d/init.d/livesys-late
/sbin/chkconfig --add livesys-late

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
echo "Packages within this LiveCD"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
#/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

%end

%post --nochroot
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
  if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
  cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS
fi

# copy scripts
echo "read CLCDDIR var"
read CLCDDIR < CLCDDIRvar
echo "CLCDDIR is $CLCDDIR"

# autostart apps and related scripts
cp -p $CLCDDIR/install/autostart/*.desktop $INSTALL_ROOT/usr/share/applications/
cp -ar $CLCDDIR/install/scripts/*.sh $INSTALL_ROOT/usr/local/bin/
chmod a+x $INSTALL_ROOT/usr/local/bin/*.sh
mkdir -p $INSTALL_ROOT/usr/local/doc
mkdir -p $INSTALL_ROOT/usr/local/doc/pvzd
cp -p $CLCDDIR/install/doc/lxterminal.conf $INSTALL_ROOT/usr/local/doc/pvzd/

#copy sudoers file
cp -ar $CLCDDIR/install/sudoers.d/predocker $INSTALL_ROOT/etc/sudoers.d/predocker
chown root:root $INSTALL_ROOT/etc/sudoers.d/predocker

%end

%post
# LXDE and LXDM configuration

# create /etc/sysconfig/desktop (needed for installation)
cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/startlxde
DISPLAYMANAGER=/usr/sbin/lxdm
EOF

cat >> /etc/rc.d/init.d/livesys << EOF
# disable screensaver locking and make sure gamin gets started
cat > /etc/xdg/lxsession/LXDE/autostart << FOE
/usr/libexec/gam_server
@lxpanel --profile LXDE
@pcmanfm --desktop --profile LXDE
/usr/libexec/notification-daemon
FOE

# set up preferred apps
cat > /etc/xdg/libfm/pref-apps.conf << FOE
[Preferred Applications]
WebBrowser=firefox.desktop
FOE

# set up auto-login for liveuser
sed -i 's/# autologin=.*/autologin=liveuser/g' /etc/lxdm/lxdm.conf
rm -rf /usr/share/applications/liveinst.desktop

#Show Docker scripts on the Desktop
mkdir -p /home/liveuser/Desktop
cp /usr/share/applications/docker-app1.desktop /home/liveuser/Desktop
cp /usr/share/applications/dockerapp-mon.desktop /home/liveuser/Desktop
#cp /usr/share/applications/lxterminal.desktop /home/liveuser/Desktop
cp /usr/share/applications/dockerterminal.desktop /home/liveuser/Desktop

#Austart Docker scripts
mkdir -p /home/liveuser/.config/autostart
cp /usr/share/applications/docker-app1.desktop /home/liveuser/.config/autostart
cp /usr/share/applications/dockerapp-mon.desktop /home/liveuser/.config/autostart
#cp /usr/share/applications/lxterminal.desktop /home/liveuser/.config/autostart

##Terminal hide menubar
mkdir -p /home/liveuser/.config/lxterminal
cp -p /usr/local/doc/pvzd/lxterminal.conf /home/liveuser/.config/lxterminal/
##sed doesn't work here
#sed -i 's/hidemenubar=false/hidemenubar=true/' /home/liveuser/.config/lxterminal/lxterminal.conf
#sed -i 's/fontname=.*/fontname=Liberation\ Mono\ 10/' /home/liveuser/.config/lxterminal/lxterminal.conf

#Docker
mkdir -p /mnt/docker
sed -i 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd -g \/mnt\/docker -G docker/' /usr/lib/systemd/system/docker.service

# create default config for clipit, otherwise it displays a dialog on startup
mkdir -p /home/liveuser/.config/clipit
cat > /home/liveuser/.config/clipit/clipitrc  << FOE
[rc]
use_copy=true
save_uris=true
save_history=false
statics_show=true
single_line=true
FOE

rm -rf /home/liveuser/desktop/liveinst.desktop

hostnamectl set-hostname livecd --static

# this goes at the end after all other changes.
chown -R liveuser:liveuser /home/liveuser

# Fixing default locale to de
localectl set-keymap de
localectl set-x11-keymap de

# restorecon -R /home/liveuser #not needed no SELinux

EOF

%end
