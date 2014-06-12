require 'devise/strategies/base'
require 'omniauth-vph'

module Devise
  module Strategies
    # Strategy for signing in a user, based on a MI authenticatable token.
    # This works for both params and http. For the former, all you need to
    # do is to pass the params in the URL:
    #
    #   http://myapp.example.com/?mi_ticket=MI_TOKEN
    #   http://myapp.example.com Header: MI_TOKEN: MI_TOKEN
    class MiTokenAuthenticatable < Authenticatable

      def valid?
        super || mi_ticket
      end

      def authenticate!
        return fail(:invalid_ticket) unless mi_ticket
        begin
          mi_user_info = adaptor.user_info mi_ticket
          return fail!(:invalid_credentials) if !mi_user_info

          auth = adaptor.map_user(mi_user_info)
          return fail(:invalid_mi_ticket) unless auth

          resource = mapping.to.vph_find_or_create(
              ::OmniAuth::AuthHash.new({info: auth}))
          resource = sudo!(resource, sudo_as) if sudo_as

          return fail(:invalid_mi_ticket) unless resource
          resource.mi_ticket = mi_ticket
          success!(resource)
        rescue Exception => e
          return fail(:master_interface_error)
        end
      end

      private

      def adaptor
        @adaptor ||= ::OmniAuth::Vph::Adaptor.new({
            host: Air.config.vph.host,
            roles_map: Air.config.vph.roles_map,
            ssl_verify: Air.config.vph.ssl_verify
          })
      end

      def mi_ticket
        params[Air.config.mi_authentication_key] || request.headers[Air.config.header_mi_authentication_key]
      end

      def sudo_as
        params[:sudo] || request.headers['HTTP_SUDO']
      end

      def sudo!(user, sudo_as)
        sudo_fail!(403, 'Must be admin to use sudo') unless user.admin?
        user = User.find_by(login: sudo_as)
        return sudo_fail!(404, "No user login for: #{sudo_as}") unless user

        user
      end

      def sudo_fail!(status, msg)
        body = {error: msg}
        headers = {"Content-Type" => "application/json; charset=utf-8"}

        custom! [status, headers, [body.to_json]]
        throw :warden
      end
    end
  end
end