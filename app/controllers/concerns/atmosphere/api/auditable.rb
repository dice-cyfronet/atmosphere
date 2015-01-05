# Audiatable creates messages in user_action.log for methods which changes
# state (create, update, destroy). Before action is executed first message
# is created. After action is executed second log (with success or failure
# information) is created.
#
# Important! Auditable concert need to be added AFTER cancan initialization.
#
module Atmosphere
  module Api
    module Auditable
      extend ActiveSupport::Concern

      included do
        around_action :audit, only: [:create, :update, :destroy]
      end

      private

      def audit
        audit_log("user_action.#{action_name}_started", params)

        yield

        if success?
          audit_log("user_action.#{action_name}_finished",
                    resource.try(:to_json))
        else
          audit_log("user_action.#{action_name}_error",
                    resource.try(:errors).try(:to_json))
        end
      rescue StandardError => e
        audit_log("user_action.#{action_name}_error", e)
        raise
      end

      def audit_log(template, params)
        log_user_action I18n.
          t(template,
            name: resource_name.humanize.downcase,
            id: resource.try(:id),
            params: params)
      end

      def resource_name
        @resource_name ||= controller_name.singularize
      end

      def resource
        @resource ||= instance_variable_get("@#{resource_name}")
      end

      def success?
        (200..299).include? response.status
      end
    end
  end
end
