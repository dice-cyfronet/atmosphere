module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_set, :class => "ApplianceSet", :parent => false

      #skip_authorization_check
      respond_to :json

      def appliance_instances
        object = Hash.new

        appliance_sets = ApplianceSet.where("appliance_sets.appliance_set_type = 'portal'").
            joins(:appliances).references(:appliances).
            joins(:appliances => :deployments).references(:appliances => :deployments).
            includes(:appliances => { :deployments => :virtual_machine }).references(:appliances => { :deployments => :virtual_machine })

        object[:appliance_set] = appliance_sets.first
        object[:appliances] = appliance_set.appliances

        render json: object, serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
