#!/bin/bash
# Managed by puppet (private repo https://github.com/ngiger/vagrant-ngiger)
if [ ! -d /mnt/encrypted ]
then
 echo not here
 exit 0
fi

umount /mnt/encrypted
/sbin/cryptsetup luksClose encrypted
