#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  %w(munge slurm-llnl slurm-llnl-basic-plugins).each do |name|
    package name
  end

  cookbook_file "/etc/munge/munge.key" do
    source "private/munge.key" # see private/munge.key-README to generate munge.key.
    owner "munge"
    group "munge"
    mode "0400"
  end

  service "munge" do
    action :start
  end

  service "slurm-llnl" do
    action :start
  end

  template "/etc/slurm-llnl/slurm.conf" do
    control_machine = search(:node, "role:banana_head AND chef_environment:#{node.chef_environment}").first
    variables(:control_machine => control_machine)
    mode "0644"
    notifies :restart, "service[slurm-llnl]"
  end

  ruby_block "/etc/default/slurm-llnl" do
    block do
      lines = File.readlines(name).reject { |s| s =~ /^# .*ulimit/ || s =~ /ulimit.*unlimited$/ || s =~ /EOF$/ }
      lines += (<<'EOS').lines.map { |a| a }
# abusing this "default" file to set ulimit defaults.
ulimit -c unlimited
ulimit -d unlimited
#ulimit -e unlimited
ulimit -f unlimited
#ulimit -i unlimited
ulimit -l unlimited
ulimit -m unlimited
# ulimit -n unlimited
# ulimit -p unlimited
#ulimit -q unlimited
#ulimit -r unlimited
ulimit -s unlimited
ulimit -t unlimited
#ulimit -u unlimited
ulimit -v unlimited
#ulimit -x unlimited
EOS
      res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
      res.owner "root"
      res.group "root"
      res.mode "0644"
      res.content lines.join
      res.notifies :restart, "service[slurm-llnl]"
      res.run_action(:create)
    end
  end

end
