#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  package "atftpd"
  service "atftpd"

  installer_archive = "/root/stamps/20110106+squeeze4-amd64-netboot.tar.gz"

  cookbook_file installer_archive

  execute "extract_installer" do
    depends installer_archive
    stamps "debian-installer-extracted"
    command "tar Czxpf /srv/tftp #{installer_archive}"
  end

  cookbook_file "/srv/tftp/debian-installer/amd64/initrd.gz.banana-patch" do
    source "private/initrd.gz.banana-patch"
    # see private/initrd.gz.banana-patch-README about this file
  end

  execute "patch_initrd_to_add_nonfree_firmwares" do
    depends "debian-installer-extracted"
    stamps "debian-initrd-patched"
    command <<'EOS'
    cd /srv/tftp/debian-installer/amd64/ &&
    [ -f initrd.gz.dist ] || mv -v initrd.gz initrd.gz.dist &&
    rm -f initrd.gz.patched &&
    cat initrd.gz.dist initrd.gz.banana-patch >initrd.gz.patched &&
    chmod 644 initrd.gz.patched &&
    cp -pv initrd.gz.patched initrd.gz
EOS
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
      preseeder = search(:node, "recipes:banana\\:\\:debian_preseeder AND chef_environment:#{node.chef_environment}").first
      raise "couldn't find preseeder in expanded run_list.  consider using '$banana_dry_run = true' first." unless preseeder
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

end
