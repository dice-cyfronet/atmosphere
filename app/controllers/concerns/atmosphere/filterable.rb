moduel Atmosphere
  module Filterable
    extend ActiveSupport::Concern

    private

    def filter
      model_class.new.attributes.keys.inject({}) do |filter, attr|
        key = attr.to_sym
        filter[key] = to_array(params[key]) if params[key]
        filter
      end
    end

    def to_array(param)
      param.to_s.split(',')
    end

    def model_class
      controller_name.classify.constantize
    end
  end
end
