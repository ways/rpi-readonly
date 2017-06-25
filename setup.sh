#!/bin/bash -ex

# Based on https://hallard.me/raspberry-pi-read-only/

echo "Warning: this will not ask questions, just go for it. Backups are made where it makes sense, but please don't run this on anything but a fresh install of Raspbian (jessie). Run as root ( sudo ${0} )."

if 'root' != $( whoami ) ; then
  echo "Please run as root!"
  exit 1;
fi

apt-get remove --purge wolfram-engine triggerhappy anacron logrotate dphys-swapfile xserver-common lightdm

insserv -r x11-common;
apt-get autoremove --purge

apt-get install busybox-syslogd ntp watchdog
dpkg --purge rsyslog

cp /boot/cmdline.txt /boot/cmdline.txt.backup
echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait fastboot noswap ro" > /boot/cmdline.txt

rm -rf /var/lib/dhcp/ /var/run /var/lock /etc/resolv.conf
ln -s /tmp /var/lib/dhcp
ln -s /tmp /var/run
#ln -s /tmp /var/spool # Not replacing /var/spool, as I need my crontabs
ln -s /tmp /var/lock
touch /tmp/dhcpcd.resolv.conf;
ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

cp /etc/systemd/system/dhcpcd5 /etc/systemd/system/dhcpcd5.backup
sed -i '/PIDFile/cPIDFile=/var/run/dhcpcd.pid' /etc/systemd/system/dhcpcd5
echo "[Unit]
Description=dhcpcd on all interfaces
Wants=network.target
Before=network.target
 
[Service]
Type=forking
PIDFile=/var/run/dhcpcd.pid
ExecStart=/sbin/dhcpcd -q -b
ExecStop=/sbin/dhcpcd -x
 
[Install]
WantedBy=multi-user.target
Alias=dhcpcd5" > /etc/systemd/system/dhcpcd5

rm /var/lib/systemd/random-seed
ln -s /tmp/random-seed /var/lib/systemd/random-seed

cp /lib/systemd/system/systemd-random-seed.service /lib/systemd/system/systemd-random-seed.service.backup
echo "[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/echo '' >/tmp/random-seed
ExecStart=/lib/systemd/systemd-random-seed load
ExecStop=/lib/systemd/systemd-random-seed save" > /lib/systemd/system/systemd-random-seed.service

systemctl daemon-reload

cp /etc/cron.hourly/fake-hwclock /etc/cron.hourly/fake-hwclock.backup
echo "#!/bin/sh
#
# Simple cron script - save the current clock periodically in case of
# a power failure or other crash
 
if (command -v fake-hwclock >/dev/null 2>&1) ; then
  mount -o remount,rw /
  fake-hwclock save
  mount -o remount,ro /
fi" > /etc/cron.hourly/fake-hwclock

cp /etc/ntp.conf /etc/ntp.conf.backup
sed -i '/driftfile/c\/var\/tmp\/ntp.drift' /etc/ntp.conf

insserv -r bootlogs
insserv -r console-setup

cp /etc/fstab /etc/fstab.backup
sed -i '/noatime/noatime,ro' /etc/fstab

echo "# For Debian Jessie 
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
tmpfs           /var/log        tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0" >> /etc/fstab

echo "# set variable identifying the filesystem you work in (used in the prompt below)
set_bash_prompt(){
    fs_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p")
    PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}
 
alias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot'
alias rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot'
 
# setup fancy prompt
PROMPT_COMMAND=set_bash_prompt
" >> /etc/bash.bashrc

echo "mount -o remount,rw /
history -a
fake-hwclock save
mount -o remount,ro /
mount -o remount,ro /boot" >> /etc/bash.bash_logout

echo "watchdog-device  = /dev/watchdog
max-load-15      = 25  
watchdog-timeout = 10" >> /etc/watchdog.conf

echo "WantedBy=multi-user.target" >> /lib/systemd/system/watchdog.service

echo "Watchdog installed, but not enabled. To enable, run sudo systemctl enable watchdog"

echo "kernel.panic = 10" >> /etc/sysctl.conf
