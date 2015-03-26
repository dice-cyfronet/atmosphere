module Atmosphere
  module NicProvider
  class NullNicProvider
    def get(appl, tmpl)
      nil
    end
  end
end
end