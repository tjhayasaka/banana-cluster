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
        precompiled_ruby = "/w2/hayasaka/files/banana/debian-6.0-rvm-ruby-1.9.2-p180-20120501-00.tar.bz2"
        system("scp", "-p", precompiled_ruby, "#{host.name}:/tmp/debian-6.0-rvm-precompiled-ruby-1.9.2-p180.tar.bz2") if File.exist?(precompiled_ruby)
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

  ruby_block "add_compute_node_roles" do
    block do
      threads = []
      nodes = search(:node, "chef_environment:#{node.chef_environment}")
      nodes.map { |node| host = ::Banana.config.find_host_by_name(node.hostname); host && (host.chef_node ||= node) && host }.compact.each do |host|
        if host.chef_node.run_list.empty?
          command_line = ["knife", "node", "run_list", "add", host.chef_node.fqdn, "role[banana_compute_hostgroup_#{host.host_group.name}]"]
          puts "running #{command_line}"
          threads << Thread.new do
            system(*command_line)
          end
        end
      end
      threads.each { |th| th.join }
    end
    action :create
  end

end
