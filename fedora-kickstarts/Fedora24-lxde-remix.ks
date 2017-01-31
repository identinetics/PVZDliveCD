# PVZD-liveCD-Fedora24-lxde-Remix.ks
#
# Description:
# - PVZD Client LiveCD with the light-weight LXDE Desktop Environment
#
# Maintainer(s):
# - Rainer Hörbe <insert mail>
# - Georg Hasibether

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
repo --name='RPM Fusion for Fedora $releasever - Free - Source' --baseurl=http://download1.rpmfusion.org/free/fedora/releases/$releasever/Everything/$basearch/os/
url --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-source-$releasever&arch=$basearch
repo --name='RPM Fusion for Fedora $releasever - Free - Updates' --baseurl=http://download1.rpmfusion.org/free/fedora/updates/$releasever/$basearch/
url --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-source-$releasever&arch=$basearch


# === modify the LiveCD's content after packages have been installed ===

%include Fedora24-lxde-packages.ks
%include Fedora24-post-fixme.ks
%include liveCD-iso-to-disk.ks
%include PVZD-docker-app.ks

# === Rebranding & license ===

%post
sed -i -e 's/Generic release/PVZD Fedora Remix/g' /etc/fedora-release /etc/issue
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/
%end
