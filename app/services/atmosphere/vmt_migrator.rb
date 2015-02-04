require 'migratio/worker/openstack_amazon_migrator'
require 'migratio/worker/openstack_openstack_migrator'

module Atmosphere
  class VmtMigrator
    def initialize(virtual_machine_template,
                   source_compute_site, destination_compute_site)
      @virtual_machine_template = virtual_machine_template
      @source_compute_site = source_compute_site
      @destination_compute_site = destination_compute_site
    end

    def select_migrator_class
      case @destination_compute_site.technology
      when 'aws'
        Migratio::Worker::OpenstackAmazonMigrator
      when 'openstack'
        Migratio::Worker::OpenstackOpenstackMigrator
      end
    end

    def enqueue_job(migrator_class)
      Sidekiq::Client.push(
      'queue' => "migration_#{@source_compute_site.site_id}",
      'class' => migrator_class,
      'args' => [@virtual_machine_template.id_at_site,
                 @destination_compute_site.site_id])
    end

    def execute
      if @source_compute_site.technology == 'openstack'
        migrator_class = select_migrator_class

        if migrator_class
          enqueue_job migrator_class
        end
      end
    end
  end
end
