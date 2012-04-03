#
# Copyright 2012, Tomoaki Hayasaka
#

class ::Chef
  class Node
    def banananet_ipaddress
      addresses = node.network.interfaces.values.map { |i| i["addresses"].select { |address, data| data["family"] == "inet" && address =~ /10.90.*/ } }.map(&:keys).flatten
      addresses.first
    end
  end
end

directory "/root/stamps"

package "ntpdate"

ruby_block "/etc/default/ntpdate" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^NTPSERVERS=/ }
    lines << "NTPSERVERS=\"10.8.11.2\"\n"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.notifies :run, "execute[ntpdate]"
    res.run_action(:create)
  end
end

execute "ntpdate" do
  command "ntpdate 10.8.11.2"
  notifies :run, "execute[hwclock]"
  action :nothing
end

execute "hwclock" do
  command "hwclock --systohc --utc"
  action :nothing
end

package "ntp"
service "ntp"

ruby_block "/etc/ntp.conf" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^server / }
    lines << "server 10.8.11.2 iburst\n"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.notifies :restart, "service[ntp]"
    res.run_action(:create)
  end
end

package "console-data"

cookbook_file "/etc/rc.local" do
  owner "root"
  group "root"
  mode "0755"
end

for dirname in %w(/w0 /w1 /w2 /w3)
  directory "#{dirname}" do
    owner "root"
    group "root"
    mode "0755"
  end
end

###

package "nfs-client"

ruby_block "/etc/fstab" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^[^ ]* +\/(w0|w1|w2|w3) / }
    lines += [<<EOS]
10.8.91.1:/w0 /w0 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w1 /w1 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w2 /w2 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w3 /w3 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
EOS
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.run_action(:create)
  end
end

execute "mount_nfs" do
  command "mount -vat nfs"
end
