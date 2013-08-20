module API
  class SecurityProxies < Grape::API
    include ::API::Concerns::OwnedPayloadsHelpers

    helpers do
      def owned_payload(name)
        @proxy ||= SecurityProxy.find_by(name: name)
      end

      def new_owned_payload(attrs)
        SecurityProxy.new attrs
      end

      def all
        SecurityProxy.all
      end
    end

    resource :security_proxies do
      include ::API::Concerns::OwnedPayloads
    end
  end
end