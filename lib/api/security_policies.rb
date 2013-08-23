module API
  class SecurityPolicies < Grape::API
    include ::API::Concerns::OwnedPayloadsHelpers

    helpers do
      def owned_payload(name)
        @proxy ||= SecurityPolicy.where(name: name).first
      end

      def new_owned_payload(attrs)
        SecurityPolicy.new attrs
      end

      def all
        SecurityPolicy.all
      end
    end

    resource :security_policies do
      include ::API::Concerns::OwnedPayloads
    end
  end
end