Facter.add("pgsql_databases") do
  setcode do
    input = Facter::Util::Resolution.exec('id -u postgres>/dev/null 2>&1 && sudo -Hiu postgres psql -tAc "SELECT datname FROM pg_database;"')
    input.split("\n")
  end
end

