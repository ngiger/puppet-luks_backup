#!/bin/bash
sudo -i /etc/backup_encrypted.rb /etc /home /snapshots/yearly* > /dev/null 2>&1
