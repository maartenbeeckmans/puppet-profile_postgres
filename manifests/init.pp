#
#
#
class profile_postgres (
  Stdlib::AbsolutePath $libdir,
  String               $data_device,
  String               $version,
  String               $ip_mask_allow_all_users,
  String               $password,
  Boolean              $manage_firewall_entry,
  Boolean              $postgres_backup,
  Hash                 $databases,
  Hash                 $schemas,
  Hash                 $roles,
  Hash                 $hba_rules,
  Stdlib::AbsolutePath $backup_location,
  String               $backup_device,
  String               $backup_ssh_command,
  String               $collect_tag = lookup('postgres_tag', String, undef, 'postgres'),
) {
  profile_base::mount{ $libdir:
    device => $data_device,
  }
  -> file { "${libdir}/tmp":
    ensure => directory,
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0755',
  }

  class { 'postgresql::globals':
    manage_package_repo => false,
    version             => $version,
  }
  -> class { 'postgresql::server':
    ip_mask_allow_all_users => $ip_mask_allow_all_users,
    listen_addresses        => '*',
    postgres_password       => $password,
  }

  include profile_postgres::config_entries

  if $manage_firewall_entry {
    firewall { '05432 postgresql access':
      dport  => 5432,
      proto  => tcp,
      action => accept,
    }
  }

  if $postgres_backup {
    include profile_postgres::backup
  }

  create_resources(::postgresql::server::db, $databases)
  create_resources(::postgresql::server::schema, $schemas)
  create_resources(::postgresql::server::role, $roles)
  create_resources(::postgresql::server::pg_hba_rule, $hba_rules)

  Postgresql::Server::Db <<| tag == $collect_tag |>>
  Postgresql::Server::Schema <<| tag == $collect_tag |>>
  Postgresql::Server::Role <<| tag == $collect_tag |>>
  Postgresql::Server::Pg_hba_rule <<| tag == $collect_tag |>>
}
