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
  Boolean              $manage_package_repo,
  String               $sd_service_name,
  Array[String]        $sd_service_tags,
  String               $listen_address,
  Boolean              $manage_prometheus_exporter,
  Boolean              $manage_sd_service            = lookup('manage_sd_service', Boolean, first, true),
  String               $collect_tag                  = lookup('postgres_tag', String, undef, 'postgres'),
) {
  if $facts['os']['family'] == 'RedHat' {
    package { 'postgresql':
      ensure   => 'disabled',
      provider => 'dnfmodule',
      before   => Class['Postgresql::Server'],
    }
  }

  profile_base::mount{ $libdir:
    device => $data_device,
    owner  => 'postgres',
    group  => 'postgres',
  }
  -> file { "${libdir}/${version}":
    ensure => directory,
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0755',
  }
  -> file { "${libdir}/${version}/tmp":
    ensure => directory,
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0755',
  }

  class { 'postgresql::globals':
    encoding            => 'UTF-8',
    manage_package_repo => $manage_package_repo,
    version             => $version,
  }
  -> class { 'postgresql::server':
    ip_mask_allow_all_users => $ip_mask_allow_all_users,
    listen_addresses        => '*',
    postgres_password       => $password,
  }
  -> class { '::postgresql::client': }

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

  if $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          tcp      => "${listen_address}:5432",
          interval => '10s'
        }
      ],
      port   => 5432,
      tags   => $sd_service_tags,
    }
  }

  if $manage_prometheus_exporter {
    include profile_prometheus::postgres_exporter
  }

  create_resources(::profile_postgres::database, $databases)
  create_resources(::postgresql::server::schema, $schemas)
  create_resources(::postgresql::server::role, $roles)
  create_resources(::postgresql::server::pg_hba_rule, $hba_rules, { 'postgresql_version' => $version })

  Postgresql::Server::Db <<| tag == $collect_tag |>>
  Postgresql::Server::Schema <<| tag == $collect_tag |>>
  Postgresql::Server::Role <<| tag == $collect_tag |>>
  Postgresql::Server::Pg_hba_rule <<| tag == $collect_tag |>>
}
