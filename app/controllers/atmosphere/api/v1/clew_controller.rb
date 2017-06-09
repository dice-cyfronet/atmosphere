module Atmosphere
  module Api
    module V1
      class ClewController < Atmosphere::Api::ApplicationController

        load_and_authorize_resource :appliance_sets,
          class: 'Atmosphere::ApplianceSet',
          parent: false,
          only: :appliance_instances

        load_and_authorize_resource :appliance_types,
          class: 'Atmosphere::ApplianceType',
          parent: false,
          only: :appliance_types

        respond_to :json

        def appliance_instances
          Rails.logger.debug("Requesting instance list from clew controller.")
          appliance_set_type = params[:appliance_set_type] || :portal
          appl_sets = @appliance_sets.clew_appliances(appliance_set_type).where(user_id: current_user.id)
          render json: { appliance_sets: appl_sets }, serializer: ClewApplianceInstancesSerializer
        end

        def appliance_types
          Rails.logger.debug("Requesting AT list from clew controller.")
          Rails.logger.debug("My PDP is #{pdp.class.inspect}.")
          appliance_types = @appliance_types.active.
              includes(:tenants, :appliance_configuration_templates).
              references(:tenants, :appliance_configuration_templates).
              where(atmosphere_tenants: { id: current_user.tenants.active }).order(:id)
          Rails.logger.debug("Retrieved #{appliance_types.length} ATs in preliminary search.")
          appliance_types = pdp_class.new(current_user).filter(appliance_types, params[:mode])
          Rails.logger.debug("#{appliance_types.length} remaining after PDP filter.")
          render json: { appliance_types: appliance_types }, serializer: ClewApplianceTypesSerializer
        end

#        def pdp
#          Atmosphere.at_pdp(current_user)
#        end

        def load_admin_abilities?
          to_boolean(params[:all])
        end
      end
    end
  end
end
