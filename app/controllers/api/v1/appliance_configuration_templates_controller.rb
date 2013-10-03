module Api
  module V1
    class ApplianceConfigurationTemplatesController < Api::ApplicationController
      before_filter :index_templates, only: :index
      load_and_authorize_resource :appliance_configuration_template
      respond_to :json

      def index
        respond_with @appliance_configuration_templates.where(filter)
      end

      def show
        respond_with @appliance_configuration_template
      end

      private

      def index_templates
        if current_user
          @appliance_configuration_templates = load_all? ? ApplianceConfigurationTemplate.all : ApplianceConfigurationTemplate.joins(:appliance_type).where("appliance_types.visibility='published' or appliance_types.user_id=?", current_user.id)
        end
      end

      def filter
        filter = {}
        ApplianceConfigurationTemplate.new.attributes.keys.each do |attr|
          key = attr.to_sym
          filter[key] = params[key].to_s.split(',') if params[key]
        end
        filter
      end

      def appliance_configuration_template_params
        params.require(:appliance_configuration_template).permit(:name, :payload, :appliance_type_id)
      end
    end
  end
end