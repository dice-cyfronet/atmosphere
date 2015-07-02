require 'migratio/worker/openstack_amazon_migrator'
require 'migratio/worker/openstack_openstack_migrator'

module Atmosphere
  class VmtMigrator
    def initialize(virtual_machine_template,
                   source_tenant, destination_tenant)
      @virtual_machine_template = virtual_machine_template
      @source_tenant = source_tenant
      @destination_tenant = destination_tenant
    end

    def execute
      if @source_tenant.technology == 'openstack'
        migrator_class = select_migrator_class

        if migrator_class
          enqueue_job migrator_class
        end
      end
    end

    private

    def select_migrator_class
      case @destination_tenant.technology
      when 'aws'
        Migratio::Worker::OpenstackAmazonMigrator
      when 'openstack'
        Migratio::Worker::OpenstackOpenstackMigrator
      end
    end

    def enqueue_job(migrator_class)
      Sidekiq::Client.push(
      'queue' => "migration_#{@source_tenant.tenant_id}",
      'class' => migrator_class,
      'args' => [@virtual_machine_template.id_at_site,
                 @destination_tenant.tenant_id])
    end
  end
end
