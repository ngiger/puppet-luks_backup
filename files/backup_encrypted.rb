#!/usr/bin/ruby
# Thanks to http://www.hermann-uwe.de/blog/howto-disk-encryption-with-dm-crypt-luks-and-debian
# Copyright 2013 by Niklaus Giger <niklaus.giger@member.fsf.org>
# License GPLv3

require 'pathname'
require 'optparse'
options = {}
options[:dryRun]    = false
options[:init]      = false
options[:device]    = "/dev/sdc1"
options[:exclude]   = "ungesichert"
options[:keyfile]   = "/etc/backup.key"
options[:logfile]   = "/var/log/#{File.basename(__FILE__)}.log"
options[:mountId]    = 'encrypted'
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options] backup_sources ... \n" +
      "  Backup to an encrypted partition (usually on an external device) using rsync.\n"+
      "  Creates a log file unter #{options[:logfile]}.\n"+
      "  Backup has a low priority (no other process is doing I/O).\n"+
      "  Uses the key file #{options[:keyfile]}. Keep a copy of it on all computers where you would like to read the backup."
  opts.on("-n", "--[no-]dry-run", "Don't run commands, just show them") do |v|
    options[:dryRun] = v
  end
  opts.on("-i", "--init", "Initialize a device. Creates also the keyfile if not already present") do |v|
    options[:init] = v
  end
  opts.on("-d", "--device name", "Use this device. Defaults to  #{options[:device]}") do |v|
    options[:device] = v
  end
  opts.on("-e", "--exclude pattern", "Use this exclude pattern. Defaults to  #{options[:exclude]}") do |v|
    options[:exclude] = v
  end
  opts.on("-k", "--keyfile name", "Use this keyfile. Defaults to  #{options[:keyfile]}") do |v|
    options[:keyfile] = v
  end
  opts.on("-h", "--help", "Show this help") do |v|
    puts opts
    exit
  end
end.parse!

def system(cmd, dryRun = DryRun)
  puts cmd if dryRun
  return if dryRun
  res = Kernel::system(cmd)
  unless res
    Kernel::system("logger #{__FILE__}: failed running '#{cmd}'") 
    exit 2
  end
  res
end

def createMountPoint(id)
  mountPoint = "/mnt/#{id}"
  system("mkdir -p #{mountPoint}") unless File.directory?(mountPoint)
  mountPoint
end

def initEncryptedDisk(opts)
  if File.exists?(opts[:keyfile])
    puts "Not creating the keyfile as #{opts[:keyfile]} is #{File.size(opts[:keyfile])} bytes long."
  else
    system("dd if=/dev/random of=#{opts[:keyfile]} bs=1 count=4096")
    system("chmod 0644 #{opts[:keyfile]}")
  end
  system("cryptsetup --key-file #{opts[:keyfile]} luksFormat #{opts[:device]} -c aes -s 256 -h sha256")
  system("cryptsetup luksOpen --key-file #{opts[:keyfile]} #{opts[:device]} #{opts[:mountId]}")
  system("mkfs.ext3 -j -m 1 -O dir_index,filetype,sparse_super /dev/mapper/#{opts[:mountId]}")
  system("cryptsetup luksClose } #{opts[:mountId]}")
end


def runDailyBackup(opts, backupItems)
  cmd = "rsync --delete --exclude ungesichert -avzbe 'ssh -i #{opts[:keyfile]}' niklaus@praxis.schoenbucher.ch:/home/niklaus /mnt/encrypted/backup/niklaus --backup-dir=/mnt/encrypted/backup/old "
  puts cmd 
  return
  startTime = Time.now
  system("logger #{__FILE__}: started")
  mapName = "/dev/mapper/#{opts[:mountId]}"
  exit 1 unless  system("/usr/local/bin/mount_encrypted.sh --keyfile = #{opts[:keyfile]}")
  # run with ionice idle priority
  # add --progress --stats -v for interactive use
  # redirect output to log file
  cmd = "ionice --class 3 rsync -a --delete --stats -v --exclude=#{opts[:exclude]} #{backupItems} /mnt/encrypted/backup/ 2>&1 "+
        "> #{opts[:logfile]}"
  system(cmd)
  exit 1 unless system("/usr/local/bin/umount_encrypted.sh")
  runSeconds = Time.now - startTime
  system("logger #{__FILE__}: completed without errors on in #{runSeconds} seconds")
end

DryRun = options[:dryRun]
options[:init] ? initEncryptedDisk(options) : runDailyBackup(options,  ARGV.join(' '))
