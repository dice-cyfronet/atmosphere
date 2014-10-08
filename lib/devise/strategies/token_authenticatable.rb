require 'devise/strategies/base'
require 'devise/strategies/sudoable'

module Devise
  module Strategies
    # Strategy for signing in a user, based on a authenticatable token.
    # This works for both params and http. For the former, all you need to
    # do is to pass the params in the URL:
    #
    #   http://myapp.example.com/?private_token=TOKEN
    #   http://myapp.example.com Header: PRIVATE-TOKEN: TOKEN
    class TokenAuthenticatable < Authenticatable
      include Sudoable

      def valid?
        super || token
      end

      def authenticate!
        return fail(:invalid_ticket) unless token
        begin
          user = Atmosphere::User.find_by(authentication_token: token)
          user = sudo!(user, sudo_as) if sudo_as

          success!(user)
        rescue Exception => e
          return fail(:authentication_token_error)
        end
      end

      mattr_accessor :key
      @@key = 'private_token'

      def self.header_key
        @@key.upcase.gsub(/_/, '-')
      end

      private

      def token
        params[TokenAuthenticatable.key].presence ||
          request.headers[TokenAuthenticatable.header_key].presence
      end
    end
  end
end