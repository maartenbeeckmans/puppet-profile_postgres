# Profile_postgres

To enable support for el8 distributions, disable the postgresql module with the following command:

```
dnf -qy module disable postgresql
```

This should be Puppetized!

```
Error: /Stage[main]/Postgresql::Server::Initdb/File[/var/lib/pgsql/13/data]/ensure: change from 'absent' to 'directory' failed: Cannot create /var/lib/pgsql/13/data; parent directory /var/lib/pgsql/13 does not exist
```

Created directory manually
