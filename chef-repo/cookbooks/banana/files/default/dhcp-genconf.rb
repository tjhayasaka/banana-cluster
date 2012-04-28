#!/usr/bin/env ruby

# WARNING:  this file is auto-generated.  changes will be discarded on
# next chef-client run.

require "/root/lib/banana"
require "/root/etc/banana_config"

def usage_exit(stream, code)
  stream.puts "usage: $0 hostgroup"
  exit(code)
end

def hostnum_to_hostname(host_group, hostnum)
  sprintf("%s%03d", host_group.name, hostnum)
end

def find_next_unconfigured_hostnum(host_group)
  hostname = nil
  hostnum = File.read("/tmp/next_unconfigured_hostnum-#{host_group.name}").to_i rescue 1
  loop do
    hostname = hostnum_to_hostname(host_group, hostnum)
    break unless ::Banana.config.find_host_by_name(hostname)
    $stderr.puts("skipping host #{hostname} because it is already configured")
    hostnum += 1
  end
  $stderr.puts("waiting for #{hostname}...")
  hostnum
end

begin
  usage_exit($stdout, 0) if ARGV.empty?

  host_group = ::Banana.config.find_host_group_by_name(ARGV[0])
  raise "#{ARGV[0]}:  unknown host group name" unless host_group

  unless File.exist?("/tmp/banana_config.rb.part")
    File.open("/tmp/banana_config.rb.part", "a") do |f|
      f.puts "# append following lines to the host list in"
      f.puts "# chef-repo/cookbooks/banana/files/default/banana_config.rb"
      f.puts ""
    end
  end

  next_hostnum = find_next_unconfigured_hostnum(host_group)

  File.open("/var/log/syslog") do |f|
    f.seek(0, IO::SEEK_END)
    loop do
      sleep 1 # FIXME: IO.select([f]) won't work???
      f.readlines.each do |line|
        next unless line =~ / dhcpd: DHCPDISCOVER from (.*) via .*: network 10.90.0.0\/16: no free leases/
        ethernet_address = $1
        next if ::Banana.config.find_host_by_ethernet_address(ethernet_address)

        hostname = hostnum_to_hostname(host_group, next_hostnum)
        File.open("/tmp/banana_config.rb.part", "a") do |f|
          f.puts <<EOS
Banana.config.host_groups.last.hosts << ::Banana::Host.new("#{hostname}", :ethernet_address => "#{ethernet_address}")
EOS
        end
        $stderr.puts "@@@ wrote example configuration for #{hostname}"

        host_group.hosts << ::Banana::Host.new("#{hostname}", :ethernet_address => "#{ethernet_address}")

        File.open("/tmp/next_unconfigured_hostnum-#{host_group.name}", "w") { |f| f.puts next_hostnum + 1}
        next_hostnum = find_next_unconfigured_hostnum(host_group)
      end
    end
  end
end
