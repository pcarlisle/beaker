%w(hypervisor).each do |lib|
  begin
    require "beaker/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

module Beaker
  class NetworkManager
    HYPERVISOR_TYPES = ['solaris', 'blimpy', 'vsphere', 'fusion', 'aix', 'vcloud', 'vagrant']

    def initialize(options, logger)
      @logger = logger
      @options = options
      @hosts = []
      @virtual_machines = {}
      @noprovision_machines = []
      @hypervisors = {}
    end

    def provision
      initialize_hosts

      if @options[:provision]
        @hypervisors.each(&:provision)
      end
    end

    def cleanup
      #only cleanup if we aren't preserving hosts
      #shut down connections
      @hosts.each {|host| host.close }

      if not @options[:preserve_hosts]
        @hypervisors.each(&:cleanup)
      end
    end

    private

    def initialize_hosts
      hosts_by_hypervisor.each do |hypervisor, hosts|
        initialized = hosts.map { |name, _| Beaker::Host.create(name, @options) }
        if hypervisor
          @hypervisors[hypervisor] = Beaker::Hypervisor.create(type, initialized, @options)
        end
        @hosts.append(initialized)
      end
    end

    def hosts_by_hypervisor
      @options['HOSTS'].group_by { |h| h['hypervisor'] }
    end
  end
end
