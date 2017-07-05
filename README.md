# rpi-readonly
Make raspberry pi raspbian file system read-only

Based on https://hallard.me/raspberry-pi-read-only/

Will also:
* prepare but not enable watchdog.
* remove software usually not needed on headless systems

TODO:
* Test
* A few operations are not repeatable, fix.
* force installs/uninstalls?
* Make sure xorg can still work.
* Check all TODOs in setup.sh
* Check if https://github.com/MarkDurbin104/rPi-ReadOnly has anything I'm missing.

Tricks for certain apps:
* Apache2, edit logpath in /etc/apache2/env
* Chromium-browser, use --user-data-dir /tmp/something
* Lightdm - fixed via setup.sh if it's installed
