#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  cookbook_file "/etc/security/limits.d/no-ulimit.conf" do
    owner "root"
    group "root"
    mode "0644"
  end

#  package "libboost-all-dev"
  package "libboost-thread-dev"

  package "imagemagick"

  package "povray"
  package "povray-doc"
  package "povray-examples"

  cookbook_file "/root/stamps/lis-1.2.62.tar.gz"
  execute "install_lis" do
    not_if "[ -f /usr/local/lib/liblis.a ]"
    command <<'EOS'
cd /root/stamps &&
tar zxf lis-1.2.62.tar.gz &&
cd lis-1.2.62 &&
./configure &&
make -j6 &&
make install
EOS
  end

end
