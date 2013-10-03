module Api
  module V1
    class ApplianceConfigurationTemplatesController < Api::ApplicationController
      # before_filter :index_templates, only: :index
      load_and_authorize_resource :appliance_configuration_template
      respond_to :json

      def index
        respond_with @appliance_configuration_templates.where(filter)
      end

      private

      def filter
        filter = {}
        ApplianceConfigurationTemplate.new.attributes.keys.each do |attr|
          key = attr.to_sym
          filter[key] = params[key].to_s.split(',') if params[key]
        end
        filter
      end
    end
  end
end