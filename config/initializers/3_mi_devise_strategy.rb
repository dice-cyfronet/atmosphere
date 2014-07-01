require 'devise/strategies/base'
require 'omniauth-vph'
require 'sudoable'

module Devise
  module Strategies
    # Strategy for signing in a user, based on a MI authenticatable token.
    # This works for both params and http. For the former, all you need to
    # do is to pass the params in the URL:
    #
    #   http://myapp.example.com/?mi_ticket=MI_TOKEN
    #   http://myapp.example.com Header: MI_TOKEN: MI_TOKEN
    class MiTokenAuthenticatable < Authenticatable
      include Sudoable

      def valid?
        super || mi_ticket
      end

      def authenticate!
        return fail(:invalid_ticket) unless mi_ticket
        begin
          mi_user_info = user_info(mi_ticket)
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

      def self.clean_cache!
        @cache && @cache.select! { |_, v| v.valid? }
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
        params[Air.config.mi_authentication_key] ||
          request.headers[Air.config.header_mi_authentication_key]
      end

      def user_info(mi_ticket)
        cached_data = cached_user_info(mi_ticket)
        if cached_data.valid?
          cached_data.user_info
        else
          load_user_info(mi_ticket)
        end
      end

      def load_user_info(mi_ticket)
        user_info = adaptor.user_info(mi_ticket)
        cache[mi_ticket] = CacheEntry.new(user_info)
        user_info
      end

      def cached_user_info(mi_ticket)
        cached = cache[mi_ticket]
        cached ? cached : NullCacheEntry.new
      end

      def cache
        @@cache ||= {}
      end

      class CacheEntry
        attr_reader :user_info

        def initialize(user_info)
          @user_info = user_info
          @timestamp = Time.now
        end

        def valid?
          (Time.now - @timestamp) < 5.minutes
        end
      end

      class NullCacheEntry
        def valid?
          false
        end
      end
    end
  end
end