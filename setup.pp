$url_root = 'https://raw.github.com/jameskyle/vagrant-setup/master/'
$pubkey = 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'

case $::osfamily {
  'RedHat': {
    $upgrade          = '/usr/bin/yum upgrade -y' 
    $packages         = ['gcc', 'kernel-devel', 'perl'] 
    $hostname_file    = '/etc/sysconfig/network'
    $hostname_content = 'NETWORKING=yes\nHOSTNAME=vagrant.virtual\n'
    $interface_file   = '/etc/sysconfig/network-scripts/ifcfg-eth0'
    $interface_source = "${url_root}/${::osfamily}/ifcfg-eth0"
  },
  'Debian': {
    $upgrade  = '/usr/bin/apt-get update && /usr/bin/apt-get dist-upgrade -y'
    $packages = ['gcc', 'make', 'linux-headers']
  },
}

define yum::groupremove ($name = $title) {
  exec {"yum::groupremove::${name}":
    user    => root,
    command => "/usr/bin/yum groupremove '${name}'"
  }
}

class vagrant::setup {
  case $::osfamily {
    'RedHat': {
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

      Yum::Groupremove<| |> -> Exec[$upgrade]
    },
    'Debian': {
      notify {'TODO: remove unnecessary debian packages':}
    }
  }
  exec { $upgrade: }
}

class vagrant::main {
  package {$packages:}
  
  file {$hostname_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '644',
    content => $hostname_content,
  }
  
  file {$interface_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => $interface_source,
  }

  user {'vagrant':
    ensure     => present,
    uid        => 1000,
    groups     => ['adm', 'vagrant'],
    home       => '/home/vagrant',
    managehome => true,
    password   => sha1('vagrant'),
    require    => Group['vagrant'],
  }

  group {'vagrant': gid => 1000 }
  file {'/home/vagrant/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'vagrant',
    group   => 'vagrant',
    require => User['vagrant'],
  }
  file {'/home/vagrant/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    owner   => 'vagrant',
    group   => 'vagrant',
    source  => $pubkey,
    require => File['/home/vagrant/.ssh']
  }
  file {'/home/vagrant/.bashrc':
    ensure  => present,
    mode    => '0644',
    owner   => 'vagrant',
    group   => 'vagrant',
    source  => "${url_root}/bashrc",
    require => User['vagrant']
  }
}

class vagrant::finalize {
  file {'/tmp/finalize.sh':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0700',
    cwd    => '/tmp',
    source => "${url_root}/finalize.sh"
  }
  exec {'finalize':
    command => "/tmp/finalize.sh",
    require => File['/tmp/finalize.sh'],
  }
}

class {'vagrant::setup': }
class {'vagrant::main': }
class {'vagrant::finalize': }

Class['vagrant::setup'] -> Class['vagrant::main'] -> Class['vagrant::finalize']
