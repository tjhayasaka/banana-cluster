#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  file "/etc/sysctl.d/banana-router.conf" do
    owner "root"
    group "root"
    mode "0644"
    content <<EOS
# this file is auto generated.  changes will be overwritten on next chef-client run.
net.ipv4.ip_forward=1
EOS
  end

end
