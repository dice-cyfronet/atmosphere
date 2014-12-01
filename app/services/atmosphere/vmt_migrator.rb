module Atmosphere
  class VmtMigrator
    def initialize(virtual_machine_template,
                   source_compute_site, destination_compute_site)
      @virtual_machine_template = virtual_machine_template
      @source_compute_site = source_compute_site
      @destination_compute_site = destination_compute_site
    end

    def execute
      if @source_compute_site.technology == 'openstack'
        migrator_class = nil

        case @destination_compute_site.technology
        when 'aws'
          migrator_class = Migration::Worker::OpenstackAmazonMigrator
        when 'openstack'
          migrator_class = Migration::Worker::OpenstackOpenstackMigrator
        end

        if !migrator_class.nil?
          Sidekiq::Client.push(
            'queue' => "migration_#{@source_compute_site.site_id}",
            'class' => migrator_class,
            'args' => [@virtual_machine_template.id_at_site,
                       @destination_compute_site.site_id])
        end
      end
    end
  end
end
