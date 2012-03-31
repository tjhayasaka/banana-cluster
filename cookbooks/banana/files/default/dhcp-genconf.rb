#!/usr/bin/env ruby

def hostname_to_hostnum(hostname)
  hostname.sub(/^.*host banana/, "").sub(/ .*$/, "").to_i
end

def hostnum_to_hostname(hostnum)
  sprintf("banana%03d", hostnum)
end

def configured_host_entries
  lines = File.readlines("/etc/dhcp/dhcpd.conf")
  lines += File.readlines("/tmp/dhcpd.conf.part") rescue []
  lines.grep(/^\s*host banana[0-9]{3} /).map(&:strip)
end

def configured_hostnames
  configured_host_entries.map { |s| s.sub(/^.*host /, "").sub(/ .*$/, "") }.sort
end

def configured_mac_addresses
  configured_host_entries.map { |s| s.sub(/^.*ethernet /, "").sub(/;.*$/, "") }.sort
end

def find_next_unconfigured_hostnum
  hostname = nil
  hostnum = File.read("/tmp/next_unconfigured_hostnum").to_i rescue 2
  configured_hostnames_ = configured_hostnames
  loop do
    hostname = hostnum_to_hostname(hostnum)
    break unless configured_hostnames_.include?(hostname)
    $stderr.puts("skipping host #{hostname} because it is already configured")
    hostnum += 1
  end
  $stderr.puts("waiting for #{hostname}...")
  hostnum
end

begin
  unless File.exist?("/tmp/dhcpd.conf.part")
    File.open("/tmp/dhcpd.conf.part", "a") do |f|
      f.puts "# append following lines to the host list in"
      f.puts "# chef-repo/cookbooks/banana/templates/default/dhcpd.conf.erb"
      f.puts ""
    end
  end

  next_hostnum = find_next_unconfigured_hostnum

  File.open("/var/log/syslog") do |f|
    f.seek(0, IO::SEEK_END)
    loop do
      sleep 1 # FIXME: IO.select([f]) won't work???
      f.readlines.each do |line|
        next unless line =~ / dhcpd: DHCPDISCOVER from (.*) via .*: network 10.90.0.0\/16: no free leases/
        mac_address = $1
        next if configured_mac_addresses.include?(mac_address)

        hostname = hostnum_to_hostname(next_hostnum)
        File.open("/tmp/dhcpd.conf.part", "a") do |f|
          f.puts <<EOS
    host #{hostname} { hardware ethernet #{mac_address}; fixed-address 10.90.0.#{next_hostnum}; }
EOS
        end
        File.open("/tmp/add_roles.rb.part", "a") do |f|
          f.puts <<EOS
knife node run_list add #{hostname}.pfsl.mech.tohoku.ac.jp "role[banana_compute]"
knife node run_list add #{hostname}.pfsl.mech.tohoku.ac.jp "role[banana_cuda_4_1]"
EOS
        end
        $stderr.puts "@@@ wrote example configuration for #{hostname}"

        File.open("/tmp/next_unconfigured_hostnum", "w") { |f| f.puts next_hostnum + 1}
        next_hostnum = find_next_unconfigured_hostnum
      end
    end
  end
end
