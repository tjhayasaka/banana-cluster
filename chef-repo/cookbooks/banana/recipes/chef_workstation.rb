#
# Copyright 2012, Tomoaki Hayasaka
#

unless $banana_dry_run

  ruby_block "bootstrap_compute_nodes" do
    only_if { File.exist?("/tmp/do-bootstrap") }
    block do
      File.delete("/tmp/do-bootstrap")
      threads = []
      ::Banana.config.hosts.select { |host| host.chef_node.nil? }.each do |host|
        # boostrap_file = ::File.expand_path("../../../../bootstrap/debian-6.0-rvm-gem",  __FILE__) # won't work because it points to chef cache
        boostrap_file = "/root/banana-chef/chef-repo/bootstrap/debian-6.0-rvm-gem" # FIXME:
        command_line = ["knife", "bootstrap", "#{host.name}.pfsl.mech.tohoku.ac.jp", "--template-file", boostrap_file]
        puts "running #{command_line}"
        threads << Thread.new do
          system(*command_line)
        end
      end
      threads.each { |th| th.join }
    end
    action :create
  end

  ruby_block "add_compute_nodes" do
    block do
      ::Banana.config.host_groups.each do |host_group|
        host_group.hosts.reject { |host| host.chef_node.nil? }.each do |host|
          true
#          $stdout.puts "knife node run_list add #{host.chef_node.fqdn} role[banana_compute_hostgroup_#{host_group.name}]"
        end
      end
    end
    action :create
  end

end
