module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      respond_to :json

      def appliance_instances
        appliance_sets = @appliance_set.where(:appliance_sets => { :appliance_set_type => :portal }).
            includes(:appliances).references(:appliances).
            includes(:appliances => :deployments).references(:appliances => :deployments).
            includes(:appliances => :appliance_type).references(:appliances => :appliance_type).
            includes(:appliances => :http_mappings).references(:appliances => :http_mappings).
            includes(:appliances => { :appliance_type => :port_mapping_templates } ).references(:appliances => { :appliance_type => :port_mapping_templates } ).
            includes(:appliances => { :deployments => :virtual_machine }).references(:appliances => { :deployments => :virtual_machine }).
            includes(:appliances => { :appliance_type => { :port_mapping_templates => :http_mappings } } ).references(:appliances => { :appliance_type => { :port_mapping_templates => :http_mappings } }).
            includes(:appliances => { :appliance_type => { :port_mapping_templates => :endpoints } } ).references(:appliances => { :appliance_type => { :port_mapping_templates => :endpoints } }).
            includes(:appliances => { :deployments => { :virtual_machine => :port_mappings } } ).references(:appliances => { :deployments => { :virtual_machine => :port_mappings } }).
            includes(:appliances => { :deployments => { :virtual_machine => :virtual_machine_flavor } }).references(:appliances => { :deployments => { :virtual_machine => :virtual_machine_flavor } })
        render json: appliance_sets[0], serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
