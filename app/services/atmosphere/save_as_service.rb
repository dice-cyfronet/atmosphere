module Atmosphere
  class SaveAsService
    def initialize(author, appliance, params)
      @author = author
      @appliance = appliance
      @params = params
    end

    def execute
      Atmosphere::ApplianceType.transaction do
        if vm = appliance && appliance.virtual_machines.first
          @tmpl = Atmosphere::VirtualMachineTemplate.
                  create_from_vm(vm, params[:name])
        end

        Atmosphere::ApplianceType.create_from(appliance, at_params).tap do |at|
          at.virtual_machine_templates << @tmpl if @tmpl
          at.author ||= author

          at.save!

          # Create a new UAT object for local PDP
          uat = Atmosphere::UserApplianceType.new
          uat.user = author
          uat.appliance_type = at
          uat.role = 'manager'
          uat.save!
        end
      end
    rescue StandardError => e
      destroy_template
      raise e
    end

    private

    attr_reader :params, :appliance, :author

    def at_params
      params.dup.tap { |p| p['user_id'] = p.delete('author_id') }
    end

    def destroy_template
      @tmpl.perform_delete_in_cloud if @tmpl && @tmpl.id_at_site
    end
  end
end
