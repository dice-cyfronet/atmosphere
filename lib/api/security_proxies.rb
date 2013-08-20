module API
  class SecurityProxies < Grape::API

    helpers do
      def proxy
        @proxy ||= SecurityProxy.find_by(name: params[:name])
      end

      def proxy!
        unless proxy
          not_found! SecurityProxy
        end
        proxy
      end

      def user_proxy!
        proxy = proxy!
        if proxy.users.include? current_user
          proxy
        else
          render_api_error!('You are not an owner of this policy', 403)
        end
      end

      def owners
        if params[:owners]
          User.where(login: params[:owners])
        else
          [current_user]
        end
      end
    end

    resource :security_proxies do
      get do
        present SecurityProxy.all, with: Entities::SecurityProxy
      end

      get ':name/payload', requirements: { name: /#{OwnedPayloable.name_regex}/ } do
        env['api.format'] = :text
        content_type "text/plain"
        proxy!.payload
      end

      get ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
        present proxy!, with: Entities::SecurityProxy
      end

      post do
        authenticate!
        required_attributes! [:name, :payload]
        attrs = attributes_for_keys [:name, :payload]

        sec_proxy = SecurityProxy.new attrs
        sec_proxy.users << owners
        if sec_proxy.save
          present sec_proxy, with: Entities::SecurityProxy
        else
          bad_request!(:name, sec_proxy.errors[:name].first) if sec_proxy.errors[:name]
          bad_request!(:payload, sec_proxy.errors[:payload].first) if sec_proxy.errors[:payload]
        end
      end

      put ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
        authenticate!
        user_proxy!.payload = params[:payload] if params[:payload]
        user_proxy!.users = owners if params[:owners]

        present user_proxy!, with: Entities::SecurityProxy
      end

      delete ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
        authenticate!
        user_proxy!.destroy
      end
    end
  end
end