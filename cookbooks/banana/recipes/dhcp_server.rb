#
# Copyright 2012, Tomoaki Hayasaka
#

package "isc-dhcp-server"
service "isc-dhcp-server"

template "/etc/dhcp/dhcpd.conf" do
  routers = search(:node, "role:banana_router AND chef_environment:#{node.chef_environment}")
  tftp_servers = search(:node, "role:banana_tftp_server AND chef_environment:#{node.chef_environment}")
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[isc-dhcp-server]"
  variables(:routers => routers, :tftp_servers => tftp_servers)
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
