#
#
#
define profile_postgres::database (
  String           $user,
  String           $password,
  String           $owner         = $user,
  Boolean          $encrypted     = true,
  String           $grant         = 'ALL',
  Optional[String] $tag           = undef,
) {
  if $encrypted {
    $_password = postgresql_password($user, $password)
  } else {
    $_password = $password
  }

  if $tag {
    @@postgresql::server::db { $title:
      user     => $user,
      password => $_password,
      grant    => $grant,
      tag      => $tag,
    }

    @@postgresql::server::pg_hba_rule { "${title}_${facts['networking']['fqdn']}":
      type        => 'host',
      user        => $user,
      database    => $title,
      auth_method => 'password',
      address     => "${facts['networking']['ip']}/32",
      description => "Allow ${title} from ${facts['networking']['fqdn']}"
      tag         => $tag,
    }
  } else {
    postgresql::server::db { $title:
      user     => $user,
      password => $_password,
      grant    => $grant,
    }
  }
}
