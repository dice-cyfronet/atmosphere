module Atmosphere
  module CancanStrongParams
    extend ActiveSupport::Concern

    included do
      # strong parameters and cancan
      before_filter do
        resource = controller_name.singularize.to_sym
        method = "#{resource}_params"
        params[resource] &&= send(method) if respond_to?(method, true)
      end
    end
  end
end
