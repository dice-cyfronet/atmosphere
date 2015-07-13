module Atmosphere
  module FlavorUpdaterExt
    extend ActiveSupport::Concern

    # By default do nothing. It can be extendend in target project and create
    # additional objects (`FlavorOsFamily`) with concreate prices. Please don't
    # save flavor or other created objects, since it will be done at the end of
    # flavor update operation.
    #
    # Flavor `cpu`, `memory` and `hdd` attributes are already set.
    def calculate_price(_flavor)
    end
  end
end
