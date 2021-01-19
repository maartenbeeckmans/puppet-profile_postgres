#
#
#
class profile_postgres::config_entries (
  Integer              $shared_buffers       = floor($::memorysize_mb * 0.25),
  Integer              $effective_cache_size = floor($::memorysize_mb * 0.5),
  Stdlib::AbsolutePath $libdir               = $::profile_postgres::libdir,
) {
  postgresql::server::config_entry { 'track_activities':
    value => 'on',
  }
  postgresql::server::config_entry { 'track_counts':
    value => 'on',
  }
  postgresql::server::config_entry { 'track_functions':
    value => 'none',
  }
  postgresql::server::config_entry { 'shared_buffers':
    value => "${shared_buffers}MB",
  }
  postgresql::server::config_entry { 'effective_cache_size':
    value => "${effective_cache_size}MB",
  }
  postgresql::server::config_entry { 'stats_temp_directory':
    value => "${libdir}/tmp/",
  }
  postgresql::server::config_entry { 'synchronous_commit':
    value => 'on',
  }
}
