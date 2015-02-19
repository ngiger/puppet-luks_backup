#
#    Copyright (C) 2014 Niklaus Giger <niklaus.giger@member.fsf.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require 'spec_helper'

describe 'luks_backup' do
  context 'when running on Debian GNU/Linux' do
    let(:title) { 'luks_backup::present' }
    let(:params) { {:ensure => 'present', :create_crontab => true} }
    it {
      should contain_class('luks_backup')
      should contain_package('anacron')
      should contain_package('rsnapshot')
      should contain_package('cryptsetup')
      should contain_file('/usr/local/bin/backup_encrypted.rb')
      should contain_file('/usr/local/bin/mount_encrypted.sh')
      should contain_file('/usr/local/bin/umount_encrypted.sh')
      should contain_file('/etc/rsnapshot.conf.localhost')
      should contain_file('/backup').           with({'ensure' => 'directory'})
      should contain_file('/backup/mysql').     with({'ensure' => 'directory'})
      should contain_file('/backup/postgresql').with({'ensure' => 'directory'})
      # as specified by http://www.rsnapshot.org/howto/1.2/rsnapshot-HOWTO.en.html daily should run before hourly!
      should contain_cron('hourly').  with({'command' => '/usr/bin/rsnapshot -q -c /etc/rsnapshot.conf.localhost hourly', 'hour' => [0,4,8,12,16,20]})
      should contain_cron('daily').   with({'command' => '/usr/bin/rsnapshot -q -c /etc/rsnapshot.conf.localhost daily',  'hour' => 23,   'minute' => 50})
      should contain_cron('weekly').  with({'command' => '/usr/bin/rsnapshot -q -c /etc/rsnapshot.conf.localhost weekly', 'hour' => 23,   'minute' => 40})
      should contain_cron('monthly'). with({'command' => '/usr/bin/rsnapshot -q -c /etc/rsnapshot.conf.localhost monthly','hour' => 23,   'minute' => 30})
      should contain_cron('yearly').  with({'command' => '/usr/bin/rsnapshot -q -c /etc/rsnapshot.conf.localhost yearly', 'hour' => 23,   'minute' => 20})
    }
  end
  context 'when running on Debian GNU/Linux with absent' do
    let(:title) { 'luks_backup::present' }
    let(:params) { {:ensure => 'absent'} }
    it {
      should_not contain_package('anacron')
      should_not contain_package('rsnapshot')
      should_not contain_package('cryptsetup')
      should_not contain_file('/backup')
    }
  end
end

