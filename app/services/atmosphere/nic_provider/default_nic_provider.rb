module Atmosphere
  module NicProvider
    class DefaultNicProvider
      def initialize(config)
        @tenant = config[:tenant]
      end

      def get(_appl)
        @tenant.network_id.present? ? @tenant.network_id : nil
      end
    end
  end
end