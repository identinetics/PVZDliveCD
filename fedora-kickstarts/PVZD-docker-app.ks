%post --nochroot

# get source dir
read PROJHOME < PROJHOMEvar
echo "PROJHOME is $PROJHOME"

# autostart apps and related scripts
cp -p $PROJHOME/install/autostart/*.desktop $INSTALL_ROOT/usr/share/applications/
cp -ar $PROJHOME/install/scripts/*.sh $INSTALL_ROOT/usr/local/bin/
chmod a+x $INSTALL_ROOT/usr/local/bin/*.sh
mkdir -p $INSTALL_ROOT/usr/local/doc
mkdir -p $INSTALL_ROOT/usr/local/doc/pvzd

#cp -p $PROJHOME/install/doc/lxterminal.conf $INSTALL_ROOT/usr/local/doc/pvzd/
mkdir -p $INSTALL_ROOT/etc/xfce4-terminal
cp -p $PROJHOME/install/config/terminalrc.* $INSTALL_ROOT/etc/xfce4-terminal/
mkdir -p $INSTALL_ROOT/usr/local/config/xfce4-terminal/
cp -p $PROJHOME/install/config/terminalrc.* $INSTALL_ROOT/usr/local/config/xfce4-terminal/

#copy sudoers filef
cp -ar $PROJHOME/install/sudoers.d/predocker $INSTALL_ROOT/etc/sudoers.d/predocker
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
cp /usr/share/applications/dockerterminal.desktop /home/liveuser/Desktop
cp /usr/share/applications/initusbdrive.desktop /home/liveuser/Desktop

#Autostart Docker scripts
mkdir -p /home/liveuser/.config/autostart
cp /usr/share/applications/docker-app1.desktop /home/liveuser/.config/autostart
cp /usr/share/applications/dockerapp-mon.desktop /home/liveuser/.config/autostart
cp /usr/share/applications/initusbdrive.desktop /home/liveuser/.config/autostart

##LX Terminal hide menubar (replaced by Xfce4-terminal: LX-terminal is hard to customize)
#cp /usr/share/applications/lxterminal.desktop /home/liveuser/.config/autostart
#mkdir -p /home/liveuser/.config/lxterminal
#cp -p /usr/local/doc/pvzd/lxterminal.conf /home/liveuser/.config/lxterminal/
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

#Don't show sudoers lecture
cat > /etc/sudoers.d/privacy <<FOE
Defaults    lecture = never
FOE

# this goes at the end after all other changes.
chown -R liveuser:liveuser /home/liveuser

# Fixing default locale to de
localectl set-keymap de
localectl set-x11-keymap de

%end
