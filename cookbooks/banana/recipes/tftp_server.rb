#
# Copyright 2012, Tomoaki Hayasaka
#

package "atftpd"
service "atftpd"

installer_archive = "/root/stamps/20110106+squeeze4-amd64-netboot.tar.gz"

cookbook_file installer_archive

execute "extract_installer" do
  not_if "test /root/stamps/installer-extracted -nt #{installer_archive}"
  command "tar Czxpf /srv/tftp #{installer_archive} && touch /root/stamps/installer-extracted"
end

ruby_block "/srv/tftp/debian-installer/amd64/boot-screens/syslinux.cfg" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^timeout / }
    lines << "timeout 100\n"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.run_action(:create)
  end
end

ruby_block "/srv/tftp/debian-installer/amd64/boot-screens/txt.cfg" do
  block do
    preseeder = search(:node, "role:banana_debian_preseeder AND chef_environment:#{node.chef_environment}").first
    lines = File.readlines(name).reject { |s| s =~ /^.append / }
    lines << "\tappend vga=788 initrd=debian-installer/amd64/initrd.gz auto=true priority=critical interface=eth1 url=http://#{preseeder.banananet_ipaddress}:1235/preseed.txt hostname=debian domain=localdomain.local -- quiet"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.run_action(:create)
  end
end
