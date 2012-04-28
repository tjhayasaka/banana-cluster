#
# Copyright 2012, Tomoaki Hayasaka
#

package "apache2"

cookbook_file "/etc/apache2/sites-available/debian_preseed" do
  source "apache2-debian_preseed.conf"
  # FIXME: reload apache2?
end

directory "/home/www-data/" do
  owner "root"
  group "root"
  mode "0755"
end

directory "/home/www-data/banana-debian-preseed/" do
  owner "root"
  group "root"
  mode "0755"
end

template "/home/www-data/banana-debian-preseed/preseed.txt" do
  preseeder = search(:node, "recipes:banana\\:\\:debian_preseeder AND chef_environment:#{node.chef_environment}").first
  source "apache2-debian_preseed.txt.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(:preseeder => preseeder)
end

template "/home/www-data/banana-debian-preseed/rc.local-compute-bootstrap" do
  preseeder = search(:node, "recipes:banana\\:\\:debian_preseeder AND chef_environment:#{node.chef_environment}").first
  source "apache2-debian_rc.local-compute-bootstrap.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(:preseeder => preseeder)
end

file "/home/www-data/banana-debian-preseed/authorized_keys" do
  content File.read("/root/.ssh/authorized_keys")
  owner "root"
  group "root"
  mode "0644"
end

%w(ssh_host_dsa_key  ssh_host_dsa_key.pub  ssh_host_rsa_key  ssh_host_rsa_key.pub).each do |f|
  # SECURITY: BUG: FIXME:  making private key open to public
  file "/home/www-data/banana-debian-preseed/#{f}" do
    content File.read("/etc/ssh/#{f}")
    owner "root"
    group "root"
    mode "0644"
  end
end

apache_site "debian_preseed"
