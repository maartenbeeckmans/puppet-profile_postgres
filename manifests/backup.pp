#
#
#
class profile_postgres::backup (
  Stdlib::AbsolutePath $backup_location    = $::profile_postgres::backup_location,
  String               $backup_device      = $::profile_postgres::backup_device,
  String               $backup_ssh_command = $::profile_postgres::backup_ssh_command,
  String               $version            = $::profile_postgres::version,
) {
  include profile_rsnapshot::user

  profile_base::mount{ $backup_location:
    device => $backup_device,
    owner  => 'rsnapshot',
    group  => 'rsnapshot',
    mode   => '0755',
  }

  $_postgresql_backup_config = {
    'backup_location' => $backup_location,
    'version'         => $version,
  }
  file { '/usr/local/bin/postgresql_backup.sh':
    ensure  => file,
    owner   => 'rsnapshot',
    group   => 'rsnapshot',
    mode    => '0700',
    content => epp('profile_postgres/postgresql_backup.sh.epp', $_postgresql_backup_config),
  }

  # Grand permissions to rsnapshot user for backup
  postgresql::server::db { 'rsnapshot':
    user     => 'rsnapshot',
    password => 'v3ry_str0ng_p@ssw0rd',
    comment  => 'Rsnapshot User',
  }
  postgresql::server::role { 'rsnapshot':
    superuser   => true,
    createdb    => true,
    createrole  => true,
    replication => true,
  }

  @@rsnapshot::backup_script{ "backup-script ${facts['networking']['fqdn']} postgres-databases":
    command      => "${backup_ssh_command} rsnapshot@${facts['networking']['fqdn']} \"/usr/local/bin/postgresql_backup.sh\"",
    target_dir   => "${facts['networking']['fqdn']}/postgres_backup",
    concat_order => '49',
    tag          => lookup('rsnapshot_tag', String, undef, 'rsnapshot'),
  }

  @@rsnapshot::backup { "backup ${facts['networking']['fqdn']} databases":
    source     => "rsnapshot@${facts['networking']['fqdn']}:${backup_location}",
    target_dir => "${facts['networking']['fqdn']}/databases",
    tag        => lookup('rsnapshot_tag', String, undef, 'rsnapshot'),
  }
}
