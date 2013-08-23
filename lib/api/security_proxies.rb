module API
  class SecurityProxies < Grape::API
    include ::API::Concerns::OwnedPayloadsHelpers

    helpers do
      def owned_payload_class
        SecurityProxy
      end
    end

    resource :security_proxies do
      include ::API::Concerns::OwnedPayloads
    end
  end
end