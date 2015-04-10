module Atmosphere
  module NicProvider
    class NullNicProvider
      def get(_appl, _tmpl)
        nil
      end
    end
  end
end
