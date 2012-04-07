#
# Copyright 2012, Tomoaki Hayasaka
#

execute "preseed_slapd" do
  command <<'EOS'
debconf-set-selections <<EOF
slapd slapd/domain string local
slapd slapd/password1 password banana
slapd slapd/password2 password banana
EOF
EOS
end

package "slapd"

<<'EOS'
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/aa
EOS

gem_package "net-ldap"
gem_package "activeldap"

template "/root/bin/banana-passwd.rb" do
  ldap_server = search(:node, "role:banana_ldap_server AND chef_environment:#{node.chef_environment}").first.banananet_ipaddress
  owner "root"
  group "root"
  mode "0755"
  variables(:ldap_server => ldap_server)
end

directory "/root/etc/"

cookbook_file "/root/etc/passwd" do
  owner "root"
  group "root"
  mode "0600"
end

execute "sync_passwd" do
  command "env LC_ALL=en_US.UTF-8 /root/bin/banana-passwd.rb /root/etc/passwd 2>&1"
end
