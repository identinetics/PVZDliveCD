%post
echo "=== processing pvzd-config.ks"

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

# Remove unwanted apps in autostart and desktop
#rm -f /home/liveuser/Desktop/*.desktop
#rm -f /home/liveuser/.config/autostart/*.desktop

# Add autostart
mkdir -p /home/liveuser/.config/autostart/
cp /opt/install/autostart-and-desktop/*.desktop /home/liveuser/.config/autostart/
cp /opt/install/autostart-hidden/*.desktop /home/liveuser/.config/autostart/

# Add desktop shortcuts
mkdir -p /home/liveuser/Desktop
cp /opt/install/autostart-and-desktop/*.desktop /home/liveuser/Desktop/
cp /opt/install/desktop-no-autostart/*.desktop /home/liveuser/Desktop/
cp /usr/share/applications/midori.desktop /home/liveuser/Desktop/

##LX Terminal hide menubar (replaced by Xfce4-terminal: LX-terminal is hard to customize)
#mkdir -p /home/liveuser/.config/lxterminal
#cp -p /usr/local/doc/pvzd/lxterminal.conf /home/liveuser/.config/lxterminal/
##sed doesn't work here
#sed -i 's/hidemenubar=false/hidemenubar=true/' /home/liveuser/.config/lxterminal/lxterminal.conf
#sed -i 's/fontname=.*/fontname=Liberation\ Mono\ 10/' /home/liveuser/.config/lxterminal/lxterminal.conf

# xcfe4-terminal defaults (larger, white on black)
mkdir -p /home/liveuser/.config/xfce4/terminal
cp -p /usr/share/applications/xfce4/terminal/terminalrc /home/liveuser/.config/xfce4/terminal/


#Docker
mkdir -p /mnt/docker
sed -i 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd -g \/mnt\/docker -G docker/' /usr/lib/systemd/system/docker.service

# create default config for clipit to suppress the dialog on startup
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

# Don't show sudoers lecture
cat > /etc/sudoers.d/privacy <<FOE
Defaults    lecture = never
FOE

# add mountpoint for TRANSFER data volume (to set correct uid/gid for VFAT file system)
cat /opt/install/etc/fstab/TRANSFER.entry >> /etc/fstab

# install livecd_statusd
mkdir -p /opt/install/log
cp -r /opt/install/status /usr/local/
/bin/pip3 install jinja2 pathlib > /opt/install/log/pvzd-config-pip.log 2>&1
mkdir /home/liveuser/.config/midori
cp /opt/install/liveuser/midori-config /home/liveuser/.config/midori/config

# this goes at the end after all other changes.
chown -R liveuser:liveuser /home/liveuser

# Fixing default locale to de
localectl set-keymap de
localectl set-x11-keymap de

%end
