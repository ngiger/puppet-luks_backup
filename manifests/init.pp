# == Class: luks_backup
#
# Full description of class luks_backup here.
#
# === Parameters
#
# This class does not have any parameters. But it uses the Hiera variable luks_backup::backup_dir
#
# [*backup_dir*]
#   Defaults hiera('luks_backup::backup_dir', '/backup')
#   Directory to place backups into.
#
# [*conf_file*]
#   Defaults /etc/rsnapshot.conf.localhost
#   Configuration of rsnapshot
#
#
#  class { luks_backup:
#    backup_dir => '/mnt/tape',
#  }
#
# === Authors
#
# Niklaus Giger niklaus.giger@member.fsf.org
#
# === Copyright
#
# Copyright 2014 Niklaus Giger niklaus.giger@member.fsf.org
#
class luks_backup(
	$backup_dir     = hiera('luks_backup::backup_dir', '/backup'),
	$create_crontab = hiera('luks_backup::create_crontab',  'true'), # if nothing given we will create a /etc/rsnapshot.conf.localhost
) {

	ensure_packages['anacron', 'rsnapshot', 'cryptsetup']
	file { '/usr/local/bin/mount_encrypted.sh':  source => 'puppet:///modules/luks_backup/mount_encrypted.sh' }
	file { '/usr/local/bin/umount_encrypted.sh': source => 'puppet:///modules/luks_backup/umount_encrypted.sh' }
	file { '/usr/local/bin/backup_encrypted.rb': source => 'puppet:///modules/luks_backup/backup_encrypted.rb' }
	file { $backup_dir: ensure => directory }
	file { "$backup_dir/postgresql": ensure => directory, require => File["$backup_dir"] }
	file { "$backup_dir/mysql":      ensure => directory, require => File["$backup_dir"] }

	notify{"crate $create_crontab":}
	if ("$create_crontab" == "true") {
	notify{"cfg $conf_file":}
	$conf_file      = '/etc/rsnapshot.conf.localhost'
	file {"$conf_file":
	content => "
config_version	1.2
snapshot_root	$backup_dir
cmd_cp		/bin/cp
cmd_rm		/bin/rm
cmd_rsync	/usr/bin/rsync
cmd_logger	/usr/bin/logger
retain		hourly	6
retain		daily	7
retain		weekly	4
verbose		2
loglevel	3
lockfile	/var/run/rsnapshot.pid
no_create_root	1
backup	$backup_dir/postgresql	db_snapshots/
backup	$backup_dir/mysql	db_snapshots/
backup	/home/		localhost/
backup	/etc/		localhost/
backup	/usr/local/	localhost/
backup	/etc/puppet/hieradata	localhost/
",
	require => Package['anacron', 'rsnapshot', 'cryptsetup'],
	}
  cron { 'hourly':
      command => "/usr/bin/rsnapshot -c $conf_file hourly",
      hour    => [0,4,8,12,16,20], minute  => 0,
      require => File[$conf_file],
  }
  cron { 'daily':
      command => "/usr/bin/rsnapshot -c $conf_file daily",
      hour    => "23", minute  => 50,
      require => File[$conf_file],
  }
  cron { 'weekly':
      command => "/usr/bin/rsnapshot -c $conf_file weekly",
      hour    => "23", minute  => 40,  weekday => 'saturday',
      require => File[$conf_file],
  }
  cron { 'monthly':
      command => "/usr/bin/rsnapshot -c $conf_file monthly",
      hour    => "23", minute  => 30, monthday => 1,
      require => File[$conf_file],
  }
  cron { 'yearly':
      command => "/usr/bin/rsnapshot -c $conf_file yearly",
      hour    => "23", minute  => 20, monthday => 1, month => 1,
      require => File[$conf_file],
  }
}
}
