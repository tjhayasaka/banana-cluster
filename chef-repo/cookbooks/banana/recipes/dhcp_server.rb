#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  package "isc-dhcp-server"
  service "isc-dhcp-server"

  template "/etc/dhcp/dhcpd.conf" do
    routers = search(:node, "role:banana_router AND chef_environment:#{node.chef_environment}")
    tftp_servers = search(:node, "recipes:banana\\:\\:tftp_server AND chef_environment:#{node.chef_environment}")
    preseeder = search(:node, "recipes:banana\\:\\:debian_preseeder AND chef_environment:#{node.chef_environment}").first
    raise "couldn't find routers in expanded run_list.  consider using '$banana_dry_run = true' first." if routers.empty?
    raise "couldn't find tftp_servers in expanded run_list.  consider using '$banana_dry_run = true' first." if tftp_servers.empty?
    raise "couldn't find preseeder in expanded run_list.  consider using '$banana_dry_run = true' first." unless preseeder
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[isc-dhcp-server]"
    variables(:routers => routers, :tftp_servers => tftp_servers, :preseeder => preseeder)
  end

  ruby_block "/etc/default/isc-dhcp-server" do
    block do
      lines = File.readlines(name).reject { |s| s =~ /^INTERFACES=/ }
      lines << "INTERFACES=eth1\n"
      res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
      res.owner "root"
      res.group "root"
      res.mode "0644"
      res.content lines.join
      res.notifies :restart, "service[isc-dhcp-server]"
      res.run_action(:create)
    end
  end

  directory "/root/bin" do
    owner "root"
    group "root"
    mode "0700"
  end

  cookbook_file "/root/bin/dhcp-genconf.rb" do
    owner "root"
    group "root"
    mode "0700"
  end

end
