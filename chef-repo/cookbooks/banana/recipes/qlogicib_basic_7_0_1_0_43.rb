#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  file "/etc/ld.so.conf.d/qlogicib.conf" do
    owner "root"
    group "root"
    mode "0644"
    content <<EOS
/usr/lib64
EOS
  end

  execute "ldconfig"

  # old banana::common recipe installed libboost-all-dev and as a result, openmpi too,
  # so ensure them pureged.
  %w(mpi-default-dev openmpi-common libboost-all-dev libboost-mpi-dev libboost-mpi-python-dev libboost-mpi-1.42-dev libopenmpi-dev libopenmpi-1.3 libibverbs-dev libibverbs1).each do |pn|
    package pn do action :purge end
  end
  package "libboost-thread-dev"
  package "linux-headers-" + `uname --kernel-release`.strip
  package "rpm"
  package "flex"
  package "byacc"
  package "libsysfs-dev"
  # old ofed recipe installed tcl/tk-8.5 but they are incompatible with ofed-1.5.4.1,
  # so ensure them pureged.
  package "tk8.5-dev" do action :purge end
  package "tcl8.5-dev" do action :purge end
  package "tk8.5" do action :purge end
  package "tcl8.5" do action :purge end
  package "tk8.4-dev"

#  cookbook_file "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz"
#  cookbook_file "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patch-ofa_kernel"
  cookbook_file "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patch-infinipath-psm"
  cookbook_file "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patch-opensm"
  cookbook_file "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-ofed.conf"

  # NOTE:
  #
  #   QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz is not included in git
  #   repo.  It must be downloaded separately and placed at
  #   /w2/hayasaka/files/non-free.

  execute "extract_QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43" do
    depends "/w2/hayasaka/files/non-free/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz"
    stamps "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted"
    command "cd /root/stamps && tar zxf /w2/hayasaka/files/non-free/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43.tgz"
  end

  execute "install_iba_portconfig" do
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted"
    stamps "iba_portconfig-installed"
    command "cd /root/stamps && cp -pv QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-Tools.RHEL5-x86_64.7.0.1.0.36/bin/iba_portconfig /usr/sbin/"
  end

  directory "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-dist"
  directory "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-patched"
  # make /root/rpmbuild because rpmbuild doesn't consider --buildroot for some unknown reason
  directory "/root/rpmbuild"
  directory "/root/rpmbuild/SOURCES"
  directory "/root/rpmbuild/SPECS"
  directory "/root/rpmbuild/SRPMS"

  def patch_srpm(srpm, tgz, rpms)
    package = srpm.sub(/-[0-9].*/, "")
    tmpextract = tgz.sub(/\.(tgz|tar.gz)/, "")
    execute "patch_ofed-#{package}" do
      depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted"
      depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patch-#{package}"
      stamps "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patched-#{package}"
      tmpdir = "/tmp/banana-qlogicib-patch-$$"
      command "mkdir -v #{tmpdir} && cd #{tmpdir} && " + <<EOS
: && # extract the trees
    [ -f /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-dist/#{srpm} ] || mv -v /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS/#{srpm} /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-dist/ &&
    cat /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-dist/#{srpm} | rpm2cpio | cpio -i &&
    tar zxf #{tgz} &&
: && # apply patches
    patch -p0 </root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patch-#{package} &&
    [ \`find . -name '*.rej' -print -quit | wc -l\` == 0 ] &&
    rm -f #{tgz} &&
    tar zcf #{tgz} #{tmpextract} &&
    rm -fr #{tmpextract} &&
: && # build the SRPMs back.  using /root/rpmbuild because rpmbuild doesn't consider --buildroot for some unknown reason
    mv #{tgz} /root/rpmbuild/SOURCES/ &&
    mv #{package}.spec /root/rpmbuild/SPECS/ &&
    rpmbuild -bs /root/rpmbuild/SPECS/#{package}.spec &&
    mv /root/rpmbuild/SRPMS/#{srpm} /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-patched/ &&
    cp -pv /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS-patched/#{srpm} /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/SRPMS/ &&
: &&
    rm -f #{rpms.map { |s| s.sub(/^/, "/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/RPMS/debian/x86_64/") }.join(" ")}
EOS
    end
  end

  patch_srpm "infinipath-psm-1.14-1.src.rpm", "infinipath-psm-1.14.tar.gz", ["infinipath-psm-*"]
  patch_srpm "opensm-3.3.9-1.src.rpm", "opensm-3.3.9.tar.gz", ["opensm-*"]

  execute "patch_install_pl" do
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted"
    stamps "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patched-install_pl"
    tmpdir = "/tmp/banana-ofed_1_5_4_1-patch-$$"
    command "mkdir -v #{tmpdir} && cd #{tmpdir} && " + <<'EOS'
: && # patch install.pl
    sed -e 's:\(2\\.6\\.(27.*el6\)/:\1|2\\.6\\.32-5-amd64/:' /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/install.pl >/root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/install.pl.new && # NOTE: this patch is idempotent
    mv /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/install.pl.new /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/install.pl &&
    chmod 755 /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23/install.pl
EOS
  end

  execute "extract_precompiled_ofed_binary" do
    precompiled = "/w2/hayasaka/files/banana/debian-6.0-precompiled-QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-20120505-00.tar.bz2"
    not_if { !File.exist?(precompiled) } # NOTE:  order matters.  "not_if" comes first.
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted"
    stamps "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-extracted-precompiled-binary"
    command "cd /root/stamps/ && tar jxpf #{precompiled}"
  end

  execute "install_ofed" do
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patched-infinipath-psm"
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patched-opensm"
    depends "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-patched-install_pl"
    stamps "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-installed"
    #files_to_clean = %w(libibcm libibdm libibdmcom libibmad libibmscli libibsysapi libibumad) # these files are installed by banana::ofed and not cleaned by rpm...
    #files_to_clean = files_to_clean.map { |f| "/usr/lib/#{f}.*" }.join(" ")
    command "cd /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43/QLogic-OFED.RHEL5-x86_64.1.5.3.2.23 && ./install.pl -c /root/stamps/QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-ofed.conf && update-rc.d opensmd defaults"
  end

  file "/etc/opensm/partitions.conf" do
    owner "root"
    group "root"
    mode "0644"
    content "Default=0x7fff : ALL=full ;\n"
  end

  file "/etc/default/opensm" do
    owner "root"
    group "root"
    mode "0644"
    content <<EOS
#

PORTS=ALL

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

  %w(mvapich2_gcc-1.6 mvapich_gcc-1.2.0 openmpi_gcc-1.4.3).each do |mpi_impl|
    cookbook_file "/var/mpi-selector/data/#{mpi_impl}.sh" do
      source "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-#{mpi_impl}.sh"
      owner "root"
      group "root"
      mode "0644"
    end
    cookbook_file "/var/mpi-selector/data/#{mpi_impl}.csh" do
      source "QLogicIB-Basic.RHEL5-x86_64.7.0.1.0.43-#{mpi_impl}.csh"
      owner "root"
      group "root"
      mode "0644"
    end
  end

  execute "select_default_mpi_impl" do
    command "mpi-selector --system --yes --set openmpi_gcc-1.4.3"
  end

end
