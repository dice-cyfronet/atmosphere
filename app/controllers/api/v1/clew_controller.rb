module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      respond_to :json

      def appliance_instances
        appliance_set_type = params[:type] || :portal
        appl_set = @appliance_sets.clew_appliances(appliance_set_type)
        render json: {:appliance_set => appl_set[0]}, serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
