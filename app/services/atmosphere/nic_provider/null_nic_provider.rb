module Atmosphere
  module NicProvider
    class NullNicProvider
      def initialize(_config = nil)
      end
      def get(_appl, _tmpl)
        nil
      end
    end
  end
end
