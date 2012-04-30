#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

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

  # NOTE:
  #
  #   QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz is not included in git
  #   repo.  It must be downloaded separately and placed at
  #   /w2/hayasaka/files/non-free.

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

  execute "extract_precompiled_ofed_binary" do
    precompiled = "/w2/hayasaka/files/banana/debian-6.0-precompiled-OFED-1.5.4.1-20120501-00.tar.bz2"
    command "cd /root/stamps/ && tar jxpf #{precompiled}"
    only_if { File.exist?(precompiled) }
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

  execute "install_iba_portconfig" do
    depends "/w2/hayasaka/files/non-free/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz"
    stamps "iba_portconfig-installed"
    command "cd /root/stamps && tar zxf /w2/hayasaka/files/non-free/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-Tools.RHEL5-x86_64.7.0.1.0.36/bin/iba_portconfig && mv -v QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-Tools.RHEL5-x86_64.7.0.1.0.36/bin/iba_portconfig /usr/sbin/"
  end

  file "/etc/default/opensm" do
    owner "root"
    group "root"
    mode "0644"
    content <<EOS
#

sleep 5 # to wait ib if up
EOS
  end

  file "/etc/rc.local.d/99_qib_portconfig" do
    owner "root"
    group "root"
    mode "0755"
    content <<EOS
#!/bin/sh
/usr/sbin/iba_portconfig -s 4
# reset drivers as a workaround for issue #282 (port won't be up after boot)
/etc/init.d/opensmd stop
/etc/init.d/openibd restart
/etc/init.d/opensmd start
EOS
  end

  service "openibd" do
    action :start
  end

  service "opensmd" do
    action :start
    not_if "ps x | grep -v grep | grep /usr/sbin/opensm >/dev/null" # we patched the init script to sleep for a while unconditionally, so we want to avoid it
  end

  # do not execute this script on chef-client run because it affects running computations.
  # execute "/etc/rc.local.d/99_qib_portconfig"

  directory "/var/mpi-selector" do
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/var/mpi-selector/data" do
    owner "root"
    group "root"
    mode "0755"
  end

  %w(mvapich2_gcc-1.7 mvapich_gcc-1.2.0 openmpi_gcc-1.4.3).each do |mpi_impl|
    cookbook_file "/var/mpi-selector/data/#{mpi_impl}.sh" do
      source "OFED-1.5.4.1-#{mpi_impl}.sh"
      owner "root"
      group "root"
      mode "0644"
    end
    cookbook_file "/var/mpi-selector/data/#{mpi_impl}.csh" do
      source "OFED-1.5.4.1-#{mpi_impl}.csh"
      owner "root"
      group "root"
      mode "0644"
    end
  end

  execute "select_default_mpi_impl" do
    command "mpi-selector --system --yes --set openmpi_gcc-1.4.3"
  end

end
