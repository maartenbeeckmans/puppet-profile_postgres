Dir.glob(["/root/.ssh/id_*.pub", "/home/*/.ssh/id_*.pub"]).each do |glob|
  # maybe our regex fails, so jump ahead if so
  user = /\w+(?=\/\.ssh)/.match(glob).to_s
  next if user.empty?
  file = File.open(glob)
  line = file.gets.chomp
  type = line.split[0].split('-')[1]
  pubkey = line.split[1]
  comment = line.split[2]

  Facter.add("#{user}_#{type}_pubkey") do
    setcode do
      pubkey
    end
  end
  Facter.add("#{user}_#{type}_comment") do
    setcode do
      comment
    end
  end
end
Dir.glob("/var/lib/pgsql/.ssh/id_*.pub").each do |glob|
  file = File.open(glob)
  line = file.gets.chomp
  type = line.split[0].split('-')[1]
  pubkey = line.split[1]
  comment = line.split[2]

  Facter.add("postgres_#{type}_pubkey") do
    setcode do
      pubkey
    end
  end
  Facter.add("postgres_#{type}_comment") do
    setcode do
      comment
    end
  end
end
