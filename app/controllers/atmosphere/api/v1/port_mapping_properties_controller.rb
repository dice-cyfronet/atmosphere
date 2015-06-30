module Atmosphere
  module Api
    module V1
      class PortMappingPropertiesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :port_mapping_template,
          only: [:index],
          class: 'Atmosphere::PortMappingTemplate'

        load_and_authorize_resource :port_mapping_property,
          class: 'Atmosphere::PortMappingProperty'

        include Atmosphere::Api::Auditable

        before_filter :initialize_manager, only: [:create, :update, :destroy]
        respond_to :json

        def index
          respond_with @port_mapping_properties.where(filter)
        end

        def show
          respond_with @port_mapping_property
        end

        def create
          @manager.save!

          render json: @manager.object,
                 serializer: PortMappingPropertySerializer,
                 status: :created
        end

        def update
          @manager.update!(port_mapping_property_params)

          render json: @manager.object,
                 serializer: PortMappingPropertySerializer
        end

        def destroy
          if @manager.destroy
            render json: {}
          else
            render_error @manager.object
          end
        end

        private

        def port_mapping_property_params
          params.require(:port_mapping_property).permit(:key, :value, :tenant_id, :port_mapping_template_id)
        end

        def initialize_manager
          @manager = AffectedApplianceAwareManager.new(@port_mapping_property, AppliancesAffectedByPmp)
        end

        def model_class
          Atmosphere::PortMappingProperty
        end
      end # of PortMappingPropertiesController
    end # of V1
  end # of Api
end