define yum::groupremove ($name = $title) {
  exec {"yum::groupremove::${name}":
    user    => root,
    command => "/usr/bin/yum groupremove '${name}'"
  }
}

class vagrant::setup {
  yum::groupremove{[
    'Dial-up Networking Support', 
    'Base',
    'E-mail server',
    'Graphical Administration Tools',
    'Hardware monitoring utilities',
    'Legacy UNIX compatibility',
    'Networking Tools',
    'Performance Tools',
    'Perl Support',
  ]:}

  exec {'/usr/bin/yum upgrade -y': }

  Yum::Groupremove<| |> -> Exec['/usr/bin/yum upgrade -y']
}

class vagrant::main {
  package {['gcc', 'kernel-devel', 'perl']:}
  
  file {'/etc/sysconfig/network':
    ensure => present,
    owner  => root,
    group => root,
    mode => 106441,
    content => 'NETWORKING=yes\nHOSTNAME=vagrant.virtual\n',
  }

  file {'/etc/sysconfig/network-scripts/ifcfg-eth0':
    ensure => present,
    owner  => root,
    group => root,
    mode => '0644',
    content => 'DEVICE="eth0"
BOOTPROTO="dhcp"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
UUID="15b118e6-66d6-4caa-8214-9d32739ae93c"'
  }

  user {'vagrant':
    ensure => present,
    uid => 1000,
    groups => ['adm', 'vagrant'],
    home => '/home/vagrant',
    managehome => true,
    password => sha1('vagrant'),
    require => Group['vagrant'],
  }

  group {'vagrant': gid => 1000 }

  authorized_key {'vagrant-ssh-key':
    ensure => present,
    user => User['vagrant'],
    type => 'ssh-rsa',
    key => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ=='
  }
}

class vagrant::finalize {
  file {'/tmp/vmware-tools.sh':
    owner => root,
    group => root,
    mode => '0700',
    cwd => '/tmp',
    content => "#!/bin/bash
mount -t iso9660 /dev/cdrom /mnt
tar xzf /mnt/VMWareTools-*.tar.gz  -C /tmp
cd vmware-tools-distrib
./vmware-install.pl --default
"
  }
  exec {'install-vmwaretools':
    command => "/tmp/vmware-tools.sh",
    require => File['/tmp/vmware-tools.sh'],
  }

  exec {'clean-up':
    command => "/usr/bin/yum clean headers packages dbcache expire-cache -y",
  }

  exec {'remove-tmpfiles': command => "/bin/rm -rf /tmp/*",}
}

class {'vagrant::setup': }
class {'vagrant::main': }
class {'vagrant::finalize': }

Class['vagrant::setup'] -> Class['vagrant::main'] -> Class['vagrant::finalize']
