# --nochroot: make files from the build environment available
%post --nochroot

# get source dir
read PROJHOME < PROJHOMEvar
echo "PROJHOME is $PROJHOME"

# copy install dir to /opt for later distribution in chroot mode
mkdir -p $INSTALL_ROOT/opt
cp -r $PROJHOME/install $INSTALL_ROOT/opt/
cp $PROJHOME/BUILD $INSTALL_ROOT/opt/
cp $PROJHOME/REPO_STATUS $INSTALL_ROOT/opt/

# add app scripts
cp $PROJHOME/install/scripts/* $INSTALL_ROOT/usr/local/bin/
cp -r $PROJHOME/install/scripts/dscripts $INSTALL_ROOT/usr/local/bin/
chmod -R a+x $INSTALL_ROOT/usr/local/bin/*.sh
chmod a+x $INSTALL_ROOT/usr/local/bin/dscripts/*.py
mkdir -p $INSTALL_ROOT/usr/local/doc/pvzd

# add scripts for status reporting
cp -r $PROJHOME/install/status/* $INSTALL_ROOT/usr/local/status/
chmod -R a+x $INSTALL_ROOT/usr/local/status/*.sh
chmod -R a+x $INSTALL_ROOT/usr/local/status/*.py

#configure sudoers
cp -r $PROJHOME/install/sudoers.d/predocker $INSTALL_ROOT/etc/sudoers.d/predocker
chown root:root $INSTALL_ROOT/etc/sudoers.d/predocker

#configure profile.d
cp -r $PROJHOME/install/profile.d/* $INSTALL_ROOT/etc/profile.d/

# default theme for xfce4-terminal windows
mkdir -p $INSTALL_ROOT/usr/share/applications/xfce4/terminal
cp -p $PROJHOME/install/xfce4-terminal-config/terminalrc $INSTALL_ROOT/usr/share/applications/xfce4/terminal/

# setup PGP root trust for SHIVA (Docker image verification)
mkdir -p $INSTALL_ROOT/etc/pki/
cp -pr $PROJHOME/install/gpg $INSTALL_ROOT/etc/pki/

%end
