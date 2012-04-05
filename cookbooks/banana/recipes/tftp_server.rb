#
# Copyright 2012, Tomoaki Hayasaka
#

package "atftpd"
service "atftpd"

installer_archive = "/root/stamps/20110106+squeeze4-amd64-netboot.tar.gz"

cookbook_file installer_archive

execute "extract_installer" do
  depends installer_archive
  stamps "installer-extracted"
  command "tar Czxpf /srv/tftp #{installer_archive}"
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
    lines = File.readlines(name).reject { |s| s =~ /^.ipappend / || s =~ /^.append / }
    lines << "\tipappend 2\n"
    lines << "\tappend vga=788 initrd=debian-installer/amd64/initrd.gz auto=true priority=critical interface=eth1 url=http://#{preseeder.banananet_ipaddress}:1235/preseed.txt hostname=debian domain=localdomain.local -- quiet\n"
    # NOTE:  ipappend 2 and interface=auto is not working in squeeze.
    # see https://bugs.launchpad.net/ubuntu/+source/netcfg/+bug/713385
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.run_action(:create)
  end
end
