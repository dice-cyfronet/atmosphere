module Atmosphere
  module Api
    module ApplicationControllerExt
      extend ActiveSupport::Concern

      def delegate_auth
      end
    end
  end
end