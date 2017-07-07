# rpi-readonly
Make raspberry pi raspbian file system read-only

Based on https://hallard.me/raspberry-pi-read-only/

Will also:
* prepare but not enable watchdog.
* remove software usually not needed

TODO:
* Ask before install/remove software
* Check all TODOs in setup.sh
* Check if https://github.com/MarkDurbin104/rPi-ReadOnly has anything I'm missing.
* Improve boot time.

Tricks for certain apps:
* Apache2, edit logpath in /etc/apache2/env
* Chromium-browser, use --user-data-dir /tmp/something
* Lightdm - fixed via setup.sh if it's installed

Usage after setup:
* Boot will take slightly longer due to dhcpcd timeout thingy. Let me know if you have a fix.
* If you need to change anything, run rw to remount file system read/write. Then ro to make it read only.
* Logs can be read with the command readlog and readlog -f.
