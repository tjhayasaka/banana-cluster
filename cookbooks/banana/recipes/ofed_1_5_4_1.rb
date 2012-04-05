#
# Copyright 2012, Tomoaki Hayasaka
#

package "linux-headers-" + `uname --kernel-release`.strip
package "rpm"
package "flex"
package "byacc"
package "tk8.5-dev"

cookbook_file "/root/stamps/OFED-1.5.4.1.tgz"
cookbook_file "/root/stamps/OFED-1.5.4.1-patch-ofa_kernel"
cookbook_file "/root/stamps/OFED-1.5.4.1-patch-infinipath-psm"
cookbook_file "/root/stamps/OFED-1.5.4.1-patch-opensm"
cookbook_file "/root/stamps/OFED-1.5.4.1-ofed.conf"

execute "extract_ofed" do
  depends "OFED-1.5.4.1.tgz"
  stamps "OFED-1.5.4.1.tgz-extracted"
  command "cd /root/stamps/ && rm -fr OFED-1.5.4.1 && tar zxpf OFED-1.5.4.1.tgz"
end

directory "/root/stamps/OFED-1.5.4.1/SRPMS-dist"
directory "/root/stamps/OFED-1.5.4.1/SRPMS-patched"
# make /root/rpmbuild because rpmbuild doesn't consider --buildroot for some unknown reason
directory "/root/rpmbuild"
directory "/root/rpmbuild/SOURCES"
directory "/root/rpmbuild/SPECS"
directory "/root/rpmbuild/SRPMS"

def patch_srpm(srpm, tgz, rpms)
  package = srpm.sub(/-[0-9].*/, "")
  tmpextract = tgz.sub(/\.(tgz|tar.gz)/, "")
  execute "patch_ofed-#{package}" do
    depends "OFED-1.5.4.1.tgz-extracted"
    depends "OFED-1.5.4.1-patch-#{package}"
    stamps "OFED-1.5.4.1.tgz-patched-#{package}"
    tmpdir = "/tmp/banana-ofed_1_5_4_1-patch-$$"
    command "mkdir -v #{tmpdir} && cd #{tmpdir} && " + <<EOS
: && # extract the trees
    [ -f /root/stamps/OFED-1.5.4.1/SRPMS-dist/#{srpm} ] || mv -v /root/stamps/OFED-1.5.4.1/SRPMS/#{srpm} /root/stamps/OFED-1.5.4.1/SRPMS-dist/ &&
    cat /root/stamps/OFED-1.5.4.1/SRPMS-dist/#{srpm} | rpm2cpio | cpio -i &&
    tar zxf #{tgz} &&
: && # apply patches
    patch -p0 </root/stamps/OFED-1.5.4.1-patch-#{package} &&
    [ \`find . -name '*.rej' -print -quit | wc -l\` == 0 ] &&
    rm -f #{tgz} &&
    tar zcf #{tgz} #{tmpextract} &&
    rm -fr #{tmpextract} &&
: && # build the SRPMs back.  using /root/rpmbuild because rpmbuild doesn't consider --buildroot for some unknown reason
    mv #{tgz} /root/rpmbuild/SOURCES/ &&
    mv #{package}.spec /root/rpmbuild/SPECS/ &&
    rpmbuild -bs /root/rpmbuild/SPECS/#{package}.spec &&
    mv /root/rpmbuild/SRPMS/#{srpm} /root/stamps/OFED-1.5.4.1/SRPMS-patched/ &&
    cp -pv /root/stamps/OFED-1.5.4.1/SRPMS-patched/#{srpm} /root/stamps/OFED-1.5.4.1/SRPMS/ &&
: &&
    rm -f #{rpms.map { |s| s.sub(/^/, "/root/stamps/OFED-1.5.4.1/RPMS/debian/x86_64/") }.join(" ")}
EOS
  end
end

patch_srpm "ofa_kernel-1.5.4.1-OFED.1.5.4.1.src.rpm", "ofa_kernel-1.5.4.1.tgz", ["kernel-ib-*"]
patch_srpm "infinipath-psm-2.9-926.1005_open.src.rpm", "infinipath-psm-2.9-926.1005_open.tar.gz", ["infinipath-psm-*"]
patch_srpm "opensm-3.3.13-1.src.rpm", "opensm-3.3.13.tar.gz", ["opensm-*"]

execute "patch_install_pl" do
  depends "OFED-1.5.4.1.tgz-extracted"
  stamps "OFED-1.5.4.1.tgz-patched-install_pl"
  tmpdir = "/tmp/banana-ofed_1_5_4_1-patch-$$"
  command "mkdir -v #{tmpdir} && cd #{tmpdir} && " + <<'EOS'
: && # patch install.pl
    sed -e 's:\(2\\.6\\.(27.*el6\)/:\1|2\\.6\\.32-5-amd64/:' /root/stamps/OFED-1.5.4.1/install.pl >/root/stamps/OFED-1.5.4.1/install.pl.new && # NOTE: this patch is idempotent
    mv /root/stamps/OFED-1.5.4.1/install.pl.new /root/stamps/OFED-1.5.4.1/install.pl &&
    chmod 755 /root/stamps/OFED-1.5.4.1/install.pl
EOS
end

execute "install_ofed" do
  depends "OFED-1.5.4.1.tgz-patched-ofa_kernel"
  depends "OFED-1.5.4.1.tgz-patched-infinipath-psm"
  depends "OFED-1.5.4.1.tgz-patched-install_pl"
  stamps "OFED-1.5.4.1.tgz-installed"
  command "cd /root/stamps/OFED-1.5.4.1 && ./install.pl -c /root/stamps/OFED-1.5.4.1-ofed.conf && update-rc.d opensmd defaults"
end

file "/etc/opensm/partitions.conf" do
  owner "root"
  group "root"
  mode "0644"
end

service "openibd" do
  action :start
end

service "opensmd" do
  action :start
end
