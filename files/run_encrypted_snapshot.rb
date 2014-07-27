#!/usr/bin/env ruby
# Copyright (c) by Niklaus Giger <niklaus.giger@member.fsf.org>
# As simple helper script to run an rsnapshot backup with an external encrypted disk
# logs start and end to the default logger. Logs rsnapshot into /var/log/<cfg>.<action>.log
# issues a shutdown when --shutdown option is given
require 'optparse'
require 'pp'
require 'fileutils'

$shutdown = false

options = OptionParser.new do |opts|
  opts.banner = %(Usage: #{File.basename($0)} [--shutdown] rsnapshot_conf action
  Run a rsnapshot backup with an external encrypted disk
  Logs start and end to the default logger.
  Logs rsnapshot into /var/log/<rsnapshot_conf>.<action>.log
  Isues a shutdown when --shutdown option is given)
      opts.on("--shutdown", "Shutdown after performing the backup") do |v|
  $shutdown = true
      end
end
options.parse!

def system(cmd)
  puts "calling: #{cmd}" if $VERBOSE
  sleep(1)
  res = Kernel.system(cmd)
  unless res
    puts "#{File.basename(__FILE__)}: failed running #{cmd}"
    shutdownIfRequested(4)
  else
    puts "#{Time.now}: #{cmd} finished" if $VERBOSE
  end
  sleep(1)
end

def shutdownIfRequested(exitCode=nil)
  if $shutdown
    cmd = "/usr/bin/sudo /sbin/shutdown -h 2 Rasperry wird runtergefahren&"
    res = Kernel.system(cmd)
    unless res
      puts "#{File.basename(__FILE__)}: failed running #{cmd}"
      exit exitCode
    end
  end
end

unless ARGV.size == 2
	puts "#{File.basename(__FILE__)}: must have exactly to args: configuration_file action"
	exit 2
end

cfg 	= ARGV[0]
action = ARGV[1]
unless File.exists?(cfg)
	puts "Configuration file #{cfg} must exists"
	exit 3
end
logFile = "/var/log/#{File.basename(cfg)}.#{action}.log"
FileUtils.rm_f(logFile, :verbose => true)
cmds = [
	"/usr/bin/logger 'starting rsnapshot #{cfg} #{action}'",
	"/usr/local/bin/umount_encrypted.sh     2>&1 | tee #{logFile}", # ignore failures
	"/usr/local/bin/mount_encrypted.sh      1>> #{logFile} 2>> #{logFile}",
	"/usr/bin/rsnapshot -c #{cfg} #{action} 1>> #{logFile} 2>> #{logFile}",
	"/usr/local/bin/umount_encrypted.sh     1>> #{logFile} 2>> #{logFile}",
	"/usr/bin/logger 'finished rsnapshot #{cfg} #{action}'",
]

cmds.each{ |cmd| system(cmd) }

shutdownIfRequested
