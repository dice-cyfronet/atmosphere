module Atmosphere
  module Api
    module ApplicationControllerExt
      extend ActiveSupport::Concern

      def delegate_auth
      end

      def token_request?
        false
      end
    end
  end
end