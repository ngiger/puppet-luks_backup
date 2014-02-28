#!/bin/bash
# Managed by puppet (private repo https://github.com/ngiger/vagrant-ngiger)
umount /mnt/encrypted
cryptsetup luksClose encrypted
rmdir /mnt/encrypted
