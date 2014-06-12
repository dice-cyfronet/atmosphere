require 'devise/strategies/base'

module Devise
  module Strategies
    # Strategy for signing in a user, based on a authenticatable token.
    # This works for both params and http. For the former, all you need to
    # do is to pass the params in the URL:
    #
    #   http://myapp.example.com/?private_token=TOKEN
    #   http://myapp.example.com Header: PRIVATE_TOKEN: TOKEN
    class TokenAuthenticatable < Authenticatable

      def valid?
        super || token
      end

      def authenticate!
        return fail(:invalid_ticket) unless token
        begin
          user = User.find_by(authentication_token: token)

          success!(user)
        rescue Exception => e
          return fail(:master_interface_error)
        end
      end

      private

      def token
        params[Air.config.token_authentication_key].presence || request.headers[Air.config.header_token_authentication_key].presence
      end
    end
  end
end