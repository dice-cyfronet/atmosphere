module Api
  module V1
    class ApplianceConfigurationTemplatesController < Api::ApplicationController
      # https://github.com/ryanb/cancan/issues/891
      # https://github.com/rails/rails/commit/a6bc35c82cd58aac61608391f38fda4e034be0f7#diff-1 fixes this problem
      # remove manual config templates loading after rails 4.0.1 is released
      before_filter :index_templates, only: :index
      load_and_authorize_resource :appliance_configuration_template
      respond_to :json

      def index
        respond_with @appliance_configuration_templates.where(filter)
      end

      def show
        respond_with @appliance_configuration_template
      end

      def create
        @appliance_configuration_template.save!
        render json: @appliance_configuration_template, status: :created
      end

      def update
        @appliance_configuration_template.update_attributes!(update_params)
        render json: @appliance_configuration_template
      end

      def destroy
        if @appliance_configuration_template.destroy
          render json: {}
        else
          render_error @appliance_configuration_template
        end
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

      def update_params
        params.require(:appliance_configuration_template).permit(:name, :payload)
      end
    end
  end
end