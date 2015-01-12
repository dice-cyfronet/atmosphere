module Atmosphere
  class VmtMigrator
    def initialize(virtual_machine_template,
                   source_compute_site, destination_compute_site)
      @virtual_machine_template = virtual_machine_template
      @source_compute_site = source_compute_site
      @destination_compute_site = destination_compute_site
    end

    def select_migrator
      case @destination_compute_site.technology
      when 'aws'
        migrator_class = Migration::Worker::OpenstackAmazonMigrator
      when 'openstack'
        migrator_class = Migration::Worker::OpenstackOpenstackMigrator
      end
      migrator_class
    end

    def enqueue_job
      Sidekiq::Client.push(
      'queue' => "migration_#{@source_compute_site.site_id}",
      'class' => migrator_class,
      'args' => [@virtual_machine_template.id_at_site,
                 @destination_compute_site.site_id])
    end

    def execute
      if @source_compute_site.technology == 'openstack'
        migrator_class = select_migrator

        if !migrator_class.nil?
          enqueue_job
        end
      end
    end
  end
end
