module API
  class SecurityPolicies < Grape::API
    include ::API::Concerns::OwnedPayloadsHelpers

    helpers do
      def owned_payload_class
        SecurityPolicy
      end
    end

    resource :security_policies do
      include ::API::Concerns::OwnedPayloads
    end
  end
end