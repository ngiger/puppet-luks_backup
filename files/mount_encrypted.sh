#!/bin/bash -v
# Managed by puppet (private repo https://github.com/ngiger/vagrant-ngiger)
blkid -tTYPE=crypto_LUKS -l -o device /dev/s*
export device=`blkid -tTYPE=crypto_LUKS -l -o device /dev/s*`
#echo Device of encrypted harddisk is $device
if [ -z "$device" ]
then
#  echo "Could not find an encrypted harddisk  of type crypto_LUKS"
  exit 1
fi
cryptsetup luksOpen --key-file /etc/backup.key $device encrypted
if [ $? -ne 0 ] ; then exit 1; fi
mkdir -p /mnt/encrypted
if [ $? -ne 0 ] ; then exit 1; fi
mkdir -p /mnt/encrypted
mount /dev/mapper/encrypted /mnt/encrypted

