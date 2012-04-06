#
# Copyright 2012, Tomoaki Hayasaka
#

cookbook_file "/etc/security/limits.d/no-ulimit.conf" do
  owner "root"
  group "root"
  mode "0644"
end

package "libboost-all-dev"
