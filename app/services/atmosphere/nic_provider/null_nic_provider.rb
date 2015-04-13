module Atmosphere
  module NicProvider
    class NullNicProvider
      def initialize(_config = nil)
      end
      def get(_appl)
        nil
      end
    end
  end
end
