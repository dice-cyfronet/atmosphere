module API
  class SecurityProxies < Grape::API

    resource :security_proxies do
      get do
        present SecurityProxy.all, with: Entities::SecurityProxy
      end
    end
  end
end