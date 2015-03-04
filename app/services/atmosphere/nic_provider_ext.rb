module Atmosphere

  module NicProviderExt
    extend ActiveSupport::Concern

    def nics
      {}
    end

  end

end