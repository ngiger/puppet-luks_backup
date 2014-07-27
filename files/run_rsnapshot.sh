#!/bin/bash 
set -e
/usr/bin/logger "xx $0 starting" 
/usr/bin/logger "xx $0 mit $* starting" 
/usr/local/bin/umount_encrypted.sh 
/usr/local/bin/mount_encrypted.sh 
/usr/bin/rsnapshot -c /etc/rsnapshot.conf.prxserver daily  > /var/log/rsnapshot.prxserver.daily 2>&1
/usr/bin/logger "xx $0 finished" 
