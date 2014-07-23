module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      respond_to :json

      def appliance_instances
        set = @appliance_sets.clew_appliances(:portal)
        render json: (set.size>0 ? set[0] : nil), serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
