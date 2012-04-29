#
# Copyright 2012, Tomoaki Hayasaka
#

# you may want to uncomment following line on first chef-client run to
# update expanded run_list.
# $banana_dry_run = true

unless $banana_dry_run

directory "/root/lib"
cookbook_file "/root/lib/banana.rb" do
  source "lib/banana.rb"
end

directory "/root/etc"
cookbook_file "/root/etc/banana_config.rb"

ruby_block "reload_banana_config" do
  block do
    load "/root/lib/banana.rb"
    ::Banana.clear_config
    load "/root/etc/banana_config.rb"
    compute_nodes = search(:node, "recipes:banana\\:\\:compute AND chef_environment:#{node.chef_environment}")
    $stderr.puts "@@@ empty compute_nodes" if compute_nodes.empty?
    compute_nodes.each do |node|
      host = ::Banana.config.find_host_by_name(node.hostname)
      raise "#{node.hostname}:  host not found in Banana.config" unless host
      host.chef_node = node
    end
  end
  action :create
end

###

directory "/root/bin"
cookbook_file "/root/bin/wakeup-all" do mode 0755 end
cookbook_file "/root/bin/ssh-all" do mode 0755 end


# time stamping stuff

directory "/root/stamps"

# excerpt from activesupport-3.0.11
class ::Module
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?

    with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"

    alias_method without_method, target
    alias_method target, with_method

    case
      when public_method_defined?(without_method)
        public target
      when protected_method_defined?(without_method)
        protected target
      when private_method_defined?(without_method)
        private target
    end
  end
end

class TimeStamp
  attr_reader :stamp_filename

  def initialize(stamp_filename)
    @stamp_filename = stamp_filename
  end

  def put_stamp
    Chef::Log.info("Touching #{@stamp_filename}")
    # NOTE:  the timestamp resolution of ext3 is a second.  so we
    # ensure the stamp is at least 1 second later from previous one,
    # otherwise same rules may be executed on next chef-client run.
    sleep(1.1) # FIXME:  this is just a workaround
    system("/bin/touch #{@stamp_filename}")
  end
end

class ::Chef
  class Resource
    attr_reader :time_stamp

    def canonical_stamp_name(filename)
      (filename[0] == "/") ? filename : "/root/stamps/#{filename}"
    end

    def depends(*filenames)
      @stamp_depends ||= []
      @stamp_depends += filenames.map { |n| canonical_stamp_name(n) }
    end

    def stamps(filename)
      raise "you can not define multiple time stamps for a resource" if @time_stamp
      raise "order matters!  'depends' must be came earlier than 'stamps'" if depends.nil? || depends.empty?
      stamp_filename = canonical_stamp_name(filename)
      @time_stamp = TimeStamp.new(stamp_filename)
      tests = @stamp_depends.map { |dep| "test #{stamp_filename} -nt #{dep}" }
      not_if(tests.join(" && "))
      Chef::Log.debug("depends: #{stamp_filename} => #{@stamp_depends}")
      Chef::Log.debug("tests: = #{tests.inspect}")
    end
  end

  class Runner
    def run_action_with_stamping(resource, action)
      run_action_without_stamping(resource, action)
      resource.time_stamp.put_stamp if resource.updated_by_last_action? && resource.time_stamp
    end

    alias_method_chain :run_action, :stamping
  end
end


class ::Chef
  class Node
    def banananet_ipaddress
      addresses = node.network.interfaces.values.map { |i| i["addresses"].select { |address, data| data["family"] == "inet" && address =~ /10.90.*/ } }.map(&:keys).flatten
      addresses.first
    end
  end
end

package "ntpdate"

ruby_block "/etc/default/ntpdate" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^NTPSERVERS=/ }
    lines << "NTPSERVERS=\"10.8.11.2\"\n"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.notifies :run, "execute[ntpdate]"
    res.run_action(:create)
  end
end

execute "ntpdate" do
  command "ntpdate 10.8.11.2"
  notifies :run, "execute[hwclock]"
  action :nothing
end

execute "hwclock" do
  command "hwclock --systohc --utc"
  action :nothing
end

package "ntp"
service "ntp"

ruby_block "/etc/ntp.conf" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^server / }
    lines << "server 10.8.11.2 iburst\n"
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.notifies :restart, "service[ntp]"
    res.run_action(:create)
  end
end

package "console-data"

directory "/etc/rc.local.d" do
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "/etc/rc.local" do
  owner "root"
  group "root"
  mode "0755"
end

for dirname in %w(/w0 /w1 /w2 /w3)
  directory "#{dirname}" do
    owner "root"
    group "root"
    mode "0755"
  end
end

execute "preseed_config" do
  ldap_server = search(:node, "recipes:banana\\:\\:ldap_server AND chef_environment:#{node.chef_environment}").first
  raise "couldn't find ldap_server in expanded run_list.  consider using '$banana_dry_run = true' first." unless ldap_server
  ldap_server = ldap_server.banananet_ipaddress
  command <<EOS
debconf-set-selections <<EOF
nslcd nslcd/ldap-uris string ldap://#{ldap_server}/
nslcd nslcd/ldap-base string dc=local
libnss-ldapd libnss-ldapd/nsswitch multiselect group, passwd, shadow
EOF
EOS
end

package "libnss-ldapd"
package "libpam-ldapd"
package "ldap-utils" # not mandatory but for convenience

###

package "nfs-client"

ruby_block "/etc/fstab" do
  block do
    lines = File.readlines(name).reject { |s| s =~ /^[^ ]* +\/(w0|w1|w2|w3) / }
    lines += [<<EOS]
10.8.91.1:/w0 /w0 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w1 /w1 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w2 /w2 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
10.8.91.1:/w3 /w3 nfs rsize=8192,wsize=8192,nfsvers=3 0 0
EOS
    res = Chef::Resource::File.new(name, Chef::RunContext.new(node, {}))
    res.owner "root"
    res.group "root"
    res.mode "0644"
    res.content lines.join
    res.run_action(:create)
  end
end

execute "mount_nfs" do
  command "mount -vat nfs"
  action :nothing
end

package "etherwake"

end
