# WARNING:  this file is auto-generated.  changes will be discarded on
# next chef-client run.

module ::Banana
  def self.clear_config
    @@config = Config.new
  end

  def self.config
    @@config ||= Config.new
  end

  class Host
    attr_accessor :name
    attr_accessor :ethernet_address
    attr_accessor :chef_node
    attr_writer :host_group

    def initialize(name, attributes = {})
      self.name = name
      self.ethernet_address = attributes[:ethernet_address]
      self.chef_node = attributes[:chef_node]
    end

    def host_group
      ::Banana.config.update_host_groups_of_hosts unless @host_group
      @host_group
    end

    def ip_address
      @ip_address ||= begin
                        m = name.match(/^[a-z]*([0-9])([0-9]*)$/)
                        "10.90.#{m[1]}.#{m[2].to_i}"
                      end
    end

    def ip_address_prefix
      @ip_address_prefix ||= ip_address.sub(/\.[^.]*$/, "")
    end

  end

  class HostGroup
    attr_accessor :name
    attr_accessor :hosts

    def initialize(name)
      self.name = name
      self.hosts = []
    end

    def update_host_groups_of_hosts
      hosts.each { |host| host.host_group = self }
    end

    def find_host_by_name(name)
      hosts.select { |host| host.name == name }.first
    end

    def find_host_by_ethernet_address(addr)
      hosts.select { |host| host.ethernet_address == addr }.first
    end

    def ip_address_prefix
      @ip_address_prefix ||= begin
                               m = name.match(/^[a-z]*([0-9])$/)
                               "10.90.#{m[1]}"
                             end
    end

  end

  class Config
    attr_accessor :host_groups

    def initialize
      @host_groups = []
    end

    def update_host_groups_of_hosts
      host_groups.each { |host_group| host_group.update_host_groups_of_hosts }
    end

    def hosts
      host_groups.map(&:hosts).flatten
    end

    def find_host_group_by_name(name)
      host_groups.select { |host| host.name == name }.first
    end

    def find_host_by_name(name)
      host_groups.map { |host_group| host_group.find_host_by_name(name) }.compact.first
    end

    def find_host_by_ethernet_address(addr)
      host_groups.map { |host_group| host_group.find_host_by_ethernet_address(addr) }.compact.first
    end
  end
end
