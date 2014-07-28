module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      respond_to :json

      def appliance_instances
        appliance_set_type = params[:appliance_set_type] || :portal
        appl_sets = @appliance_sets.clew_appliances(appliance_set_type).where(:user_id => current_user.id)
        render json: { :appliance_sets => appl_sets }, serializer: ClewApplianceInstancesSerializer
      end

    end
  end
end
