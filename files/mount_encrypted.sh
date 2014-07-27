#!/bin/bash -v
# Managed by puppet (private repo https://github.com/ngiger/vagrant-ngiger)
set -e
/sbin/blkid -tTYPE=crypto_LUKS -l -o device /dev/s*
export device=`/sbin/blkid -tTYPE=crypto_LUKS -l -o device /dev/s*`
#echo Device of encrypted harddisk is $device
if [ -z "$device" ]
then
  echo "Could not find an encrypted harddisk  of type crypto_LUKS"
  exit 1
fi
/sbin/cryptsetup luksOpen --key-file /etc/backup.key $device encrypted
if [ $? -ne 0 ] ; then exit 1; fi
mkdir -p /mnt/encrypted
if [ $? -ne 0 ] ; then exit 1; fi
mkdir -p /mnt/encrypted
mount -odefaults,acl /dev/mapper/encrypted /mnt/encrypted

df -h
