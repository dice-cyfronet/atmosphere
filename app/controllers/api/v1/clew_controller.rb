module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_sets, :class => "ApplianceSet", :parent => false
      load_and_authorize_resource :appliance_types, :class => "ApplianceType", :parent => false

      respond_to :json

      def appliance_instances
        appliance_set_type = params[:appliance_set_type] || :portal
        appl_sets = @appliance_sets.clew_appliances(appliance_set_type).where(:user_id => current_user.id)
        render json: { :appliance_sets => appl_sets }, serializer: ClewApplianceInstancesSerializer
      end

      def appliance_types
        puts "Dsadasd"
        @appliance_types = @appliance_types.includes(:compute_sites).references(:compute_sites).active
        ats = pdp.filter(@appliance_types, params[:mode])
        render json: { :appliance_types => @appliance_types }, serializer: ClewApplianceTypesSerializer
      end

      def pdp
        Air.config.at_pdp_class.new(current_user)
      end

    end
  end
end
