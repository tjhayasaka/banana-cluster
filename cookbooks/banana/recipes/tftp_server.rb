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
