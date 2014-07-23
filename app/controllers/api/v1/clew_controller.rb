module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      respond_to :json

      def appliance_instances
        render json: @appliance_sets.clew_appliances(:portal)[0], serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
