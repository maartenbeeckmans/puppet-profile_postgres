class profile_postgres (
  Stdlib::Host $master,
  Array[Stdlib::Host] $slaves,
  String $password,
  Stdlib::Port $postgres_port = '5432',
  String $replicationuser = 'repl',
) {
  case $facts['networking']['fqdn'] {
    $master: {
      $_manage_recovery_conf = false
      postgresql::server::config_entry { 'synchronous_standy_names':
        value => '*',
      }
    }
    default: {
      $_manage_recovery_conf = true
      postgresql::server::config_entry { 'hot_standby':
        value => 'on',
      }
      postgresql::server::recovery { 'create recovery.conf':
        standby_mode     => 'on',
        primary_conninfo => "host=${master} port=${postgres_port} user=${replicationuser} password=${password}",
      }
    }
  }

  class { 'postgresql::globals':
    encoding             => 'UTF-8',
    locale               => 'en_US.UTF-8',
    manage_package_repo  => true,
    version              => 'latest',
    manage_recovery_conf => $_manage_recovery_conf,
  }
  -> class { 'postgresql::server':
    listen_addresses => "localhost,${facts['networking']['ip']}",
  }

  package { ['pg_activity', 'pgtune']:
    ensure => present,
  }
  -> user { 'postgres':
    shell          => '/bin/bash',
    home           => '/var/lib/pgsql',
    purge_ssh_keys => true,
  }
  -> file { '/usr/lib/pgsql/.ssh':
    ensure => 'directory',
    owner  => 'postgres',
    group  => 'postgres',
  }

  include ::postgresql::server::contrib

  $_type = 'ed25519'
  $_myhash = {
    root     => '/root',
    postgres => '/var/lib/pgsql'
  }
  $_myhash.each |$sshuser, $homepath| {
    ## create ssh key for $sshuser
    ssh_keygen { $sshuser:
      type => $_type,
      home => $homepath,
    }
    ## export it
    $_pubkey = getvar("::${sshuser}_${_type}_pubkey")
    $_comment = getvar("::${sshuser}_${_type}_comment")
    if $_pubkey and $_comment {
      @@ssh_authorized_key{$_comment:
        ensure  => 'present',
        type    => $_type,
        options => ['no-port-forwarding', 'no-X11-forwarding', 'no-agent-forwarding' ],
        user    => $sshuser,
        key     => $_pubkey,
        tag     => 'postgrescluster',
      }
    }
    # collect it
    Ssh_Authorized_Key <<| tag == 'postgrescluster' and title != $_comment |>>
  }
  ## export host key
  if $facts['ssh']['ecdsa']['key'] {
    @@sshkey { $facts['networking']['fqdn']:
      host_aliases => $::ipaddress,
      type         => 'ecdsa-sha2-nistp256',
      key          => $::sshecdsakey,
      tag          => 'postgrescluster',
    }
  }
  ## import host key
  Sshkey <<| tag == 'postgrescluster' and title != $::fqdn |>>
  ## setup replication user
  postgresql::server::role { $replicationuser:
    login         => true,
    replication   => true,
    password_hash => postgresql_password($replicationuser, $password),
  }
  postgresql::server::pg_hba_rule{'allow replication user to access server':
    type        => 'host',
    database    => 'replication',
    user        => $replicationuser,
    address     => '10.254.4.0/24', # TODO resrict to /32
    auth_method => 'md5',
  }
  postgresql::server::config_entry{'wal_level':
    value => 'hot_standby',
  }
  postgresql::server::config_entry{'max_wal_senders':
    value => 5,
  }
  postgresql::server::config_entry{'wal_keep_segments':
    value => 32,
  }
  postgresql::server::config_entry{'archive_mode':
    value => 'on',
  }
  postgresql::server::config_entry{'archive_command':
    value => 'cp %p /mnt/backup/%f',
  }
}
