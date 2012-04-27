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
    def initialize(name, attributes = {})
      self.name = name
      self.ethernet_address = attributes[:ethernet_address]
    end

    def ip_address
      @ip_address ||= begin
                        m = name.match(/^[a-z]*([0-9])([0-9]*)$/)
                        "10.90.#{m[1]}.#{m[2].to_i}"
                      end
    end
  end

  class HostGroup
    attr_accessor :name
    attr_accessor :hosts

    def initialize(name)
      self.name = name
      self.hosts = []
    end

    def find_host_by_name(name)
      hosts.select { |host| host.name == name }.first
    end
  end

  class Config
    attr_accessor :host_groups

    def initialize
      @host_groups = []
    end

    def find_host_group_by_name(name)
      host_groups.select { |host| host.name == name }.first
    end

    def find_host_by_name(name)
      host_groups.map { |host_group| host_group.find_host_by_name(name) }.compact.first
    end
  end
end
